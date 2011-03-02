module DAV

  module StatusMessages

    OK                    = 'HTTP/1.1 200 OK'
    FORBIDDEN             = 'HTTP/1.1 403 Forbidden'
    NOT_FOUND             = 'HTTP/1.1 404 Not Found'
    CONFLICT              = 'HTTP/1.1 409 Conflict'
    UNPROCESSABLE_ENTITY  = 'HTTP/1.1 422 Unprocessable Entity'
    FAILED_DEPENDENCY     = 'HTTP/1.1 424 Failed Dependency'
    INTERNAL_SERVER_ERROR = 'HTTP/1.1 500 Internal Server Error'

    MESSAGES = {
      200 => OK,
      403 => FORBIDDEN,
      404 => NOT_FOUND,
      409 => CONFLICT,
      422 => UNPROCESSABLE_ENTITY,
      424 => FAILED_DEPENDENCY,
      500 => INTERNAL_SERVER_ERROR
    }

    def message(status_code = code)
      MESSAGES.fetch status_code
    end
    module_function :message

  end
  module StatusCodes

    def ok!(error = nil)
      set_code 200, error
    end
    def ok?
      code == 200
    end

    def forbidden!(error = nil)
      set_code 403, error
    end
    def not_found!(error = nil)
      set_code 404, error
    end
    def conflict!(error = nil)
      set_code 409, error
    end
    def unprocessable_entity!(error = nil)
      set_code 422, error
    end
    def failed_dependency!(error = nil)
      set_code 424, error
    end
    def internal_server_error!(error = nil)
      set_code 500, error
    end

    protected

      def set_code(code, error)
        self.code = code
        self
      end

  end

  class Condition < Proc

    attr_reader :code, :error
    include StatusCodes

    def initialize
      super

      ok!
    end

    def call
      super self
    end

    def write_to(description, document = description.document)
      if @error
        child = document.create_element "#{ @error }", 'xmlns:D' => 'DAV:'
        description.add_child child
      end
    end

    def inspect
      StatusMessages.message code
    end

    protected

      def set_code(code, error)
        @code, @error = code, error
        self
      end

  end
  class Status < Condition
    include StatusMessages
    alias inspect message

    def write_to(response, document = response.document)
      child = document.create_element 'status', message, 'xmlns:D' => 'DAV:'
      response.add_child child
    end

    def call
      super
    rescue => e
      internal_server_error! "#{ e.message }\n  #{ e.backtrace.join %Q'\n  ' }"
    end

  end

  class PropertyStatus < Status

    attr_reader :properties

    def initialize
      super
      @properties = Hash.new { |mem, code| mem[code] = [] }
    end

    def write_to(response, document = response.document)
      @properties.each do |code, properties|
        next if properties.empty?

        document.create_element 'propstat', 'xmlns:D' => 'DAV:' do |stat|
          prop = document.create_element 'prop', 'xmlns:D' => 'DAV:'
          status = document.create_element 'status', message(code), 'xmlns:D' => 'DAV:'

          properties.each do |property|
            href = property.namespace.href if property.namespace
            namespaces = property.namespace_definitions

            prop.add_child property

            namespaces.each do |ns|
              namespace = property.add_namespace ns.prefix, ns.href
              property.namespace = namespace if href == ns.href
            end
          end

          stat.add_child prop
          stat.add_child status
          response.add_child stat
        end
      end
    end

  end

  class Response < Struct.new(:uri)

    def initialize(uri)
      @hooks = Hash.new { |mem, method_sym| mem[method_sym] = [] }
      super uri
    end

    def precondition
      @precondition ||= Condition.new if block_given?
      @precondition if defined? @precondition
    end
    def postcondition
      @postcondition ||= Condition.new if block_given?
      @postcondition if defined? @postcondition
    end
    def status(method_sym = nil)
      if block_given?
        @status = Status.new
      elsif method_sym
        @status = Status.new { |status| status.send method_sym }
      end

      @status if defined? @status
    end
    def property_status
      @status = PropertyStatus.new if block_given?
      @status if defined? @status
    end

    def write_to(multistatus, document = multistatus.document)
      response = document.create_element 'response'
      response.add_child document.create_element('href', uri.to_s)

      status.write_to response, document

      document.create_element 'description', 'xmlns:D' => 'DAV:' do |node|
        write_description_to node, document
        response.add_child node unless node.children.empty?
      end

      multistatus.add_child response
    end

    def finish
      @hooks[:finish].each { |hook| hook.call status }
    end

    def on(method_sym, &block)
      @hooks[method_sym] << block
    end

    protected

      def write_description_to(node, document = node.document)
        precondition.write_to node, document if precondition
        node.add_child document.create_text_node(status.error) if status.error
        postcondition.write_to node, document if postcondition
      end

  end

  class Responder < Struct.new(:request)

    attr_reader :responses

    def initialize(request = nil)
      @responses = Hash.new { |mem, uri| mem[uri] = Response.new uri }
      super request

      if block_given?
        yield self
        finish
      end
    end

    def respond_to(uri)
      yield responses[uri]
      self
    end

    def status(uri)
      @responses[uri].status
    end

    def finish
      @responses.values.
      each { |r| r.precondition.call if r.precondition }.
      each { |r| r.status.call }.
      each { |r| r.postcondition.call if r.postcondition }.
      each { |response| response.finish }
    end

    def to_xml
      document = Nokogiri::XML '<?xml version="1.0" encoding="utf-8" ?>'

      root = document.add_child document.create_element('multistatus')
      ns   = document.root.add_namespace 'D', 'DAV:'

      root.namespace = ns

      responses.values.each { |response| response.write_to root }

      document.to_xml
    end
  end

end
