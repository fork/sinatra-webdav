module DAV
  class Properties < Struct.new(:resource_id, :document)
    extend PropertyAccessors
    include DAV

    BLANK = <<-XML
<?xml version="1.0" encoding="utf-8" ?>
<D:prop xmlns:D="DAV:">
  <D:creationdate/>
  <D:displayname/>
  <D:getcontentlanguage/>
  <D:getcontentlength/>
  <D:getcontenttype/>
  <D:getetag/>
  <D:getlastmodified/>
  <D:lockdiscovery/>
  <D:resourcetype/>
  <D:supportedlock/>
  <D:getlastmodified/>
</D:prop>
XML

    # list of protected properties grouped by namespace href
    PROTECTED = Hash.new { |mem, ns| mem[ns] = [] }
    PROTECTED['DAV:'] = %w[
      displayname
      getcontentlanguage
      getcontentlength
      getcontenttype
      getetag
      getlastmodified
      lockdiscovery
      resourcetype
      supportedlock
    ]

    # raises when patch tries to modify a protected property
    class PropertyProtected < DAV::Error
      def initialize
        super 'cannot-modify-protected-property'
      end
    end
    class NullNamespace < DAV::Error
      def initialize
        super ''
      end
    end

    property :creation_date => :creationdate,
             :last_modified => :getlastmodified do

      reader { |node| str = node.content; str.empty?? nil : Time.parse(str) }
      writer { |node, time| node.content = time.httpdate }
    end

    property :display_name     => :displayname,
             :content_language => :getcontentlanguage,
             :content_type     => :getcontenttype,
             :entity_tag       => :getetag

    property :content_length => :getcontentlength do
      reader { |node| Integer node.content }
      writer { |node, value| node.content = value }
    end

    property :lock_discovery => :lockdiscovery do
      #reader {|*|}
      #writer {|*|}
    end

    property :resource_type => :resourcetype do
      reader do |node|
        node.css('*').map { |n| n.name }.join unless node.children.empty?
      end
      writer do |node, value|
        node.children.remove
        node.add_child node.document.create_element(value) unless value.nil?
      end
    end

    property :supported_lock => :supportedlock do
      #reader {|*|}
      #writer {|*|}
    end

    def self.children_by_names(names)
      names = names.map { |name| "self::D:#{ name }" }.join ' or '
      "child::*[#{ names }]"
    end

    def initialize(resource)
      data     = property_storage.get(resource.id) || BLANK
      document = Nokogiri::XML data

      @query = "/D:prop/D:%s"

      super resource.id, document
    end

    # Renders the document.
    def to_xml
      document.root.to_xml
    end

    # Copies the document to destinated properties objects.
    def copy(destination)
      destination.document = document.clone
    end

    def patch(request, response)
      request.rewind
      request = Nokogiri::XML request.read

      properties = Hash.new { |mem, modifier| mem[modifier] = [] }
      protected_properties, conflicting_properties = [], []

      response.precondition do |condition|
        unless request.root
          condition.unprocessable_entity!
        else
          request.root.elements.each do |modifier|
            if %w[ set remove ].include? modifier.name
              modifier.css('D|prop > *', 'D' => 'DAV:').each do |property|
                begin
                  protect! property
                  properties[modifier] << property

                # TODO Be more generic here so we can add custom behaviour
                #      (like Access Control, ...) to Properties#protect!
                #      method.
                rescue PropertyProtected => e
                  protected_properties << property
                  condition.forbidden! e.message if condition.ok?
                end
              end
            else
              condition.conflict!
            end
          end
        end
      end

      response.property_status do |status|
        if response.precondition.ok?
          properties.each do |modifier, props|
            props.each do |prop|
              send modifier.name, prop
              status.properties[200] << prop
            end
          end
        else
          status.properties[403] = protected_properties.
          each { |prop| prop.children.remove }
          status.properties[409] = conflicting_properties.
          each { |prop| prop.children.remove }
          status.properties[424] = properties.values.flatten.
          each { |prop| prop.children.remove }
        end
      end

      response.postcondition do |status|
        # TODO http://tools.ietf.org/html/rfc3253#section-3.12
      end

      self
    end

    ALLPROP = <<-XML
<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:allprop/>
</D:propfind>
XML

    def find(request, response)
      request.rewind
      xml = request.read
      xml = ALLPROP if xml.empty? # default: leg - wait for it - acy
      request = Nokogiri::XML xml

      nodes = document.root.elements
      nodes.each { |n| nodes << nodes.delete(n).clone } # clone warz

      response.property_status do |status|
        request.root.css('D|prop, D|propname, D|allprop', 'D' => 'DAV:').
        each do |selector|
          case selector.name
          when 'prop'
            selector.elements.each do |e|
              node = (namespace = e.namespace) ?
                nodes.at("./self::P:#{ e.name }", 'P' => namespace.href) :
                nodes.at("./self::#{ e.name }")

              if node
                status.properties[200] << node
              else
                status.properties[404] << e
              end
            end
          when 'propname'
            # NodeSet#each does return INT!
            nodes.each { |n| n.children.remove }
            status.properties[200] = nodes
          when 'allprop'
            status.properties[200] = nodes
          end
        end
      end

      self
    end

    # Compares another Properties object using the resource IDs.
    def ==(other)
      Properties === other and resource_id == other.resource_id
    end

    # Calls block for each property in all namespaces.
    def each
      if block_given?
        document.root.elements.each do |node|
          yield node.name, node.content
        end
      else
        Enumerator.new self, :each
      end
    end

    # Resource isn't a collection if its resourcetype property is self-closed.
    # Therefor the property must be nil.
    def collection?
      not resource_type.nil?
    end

    # Stores the current xml presentation in the storage
    def store
      property_storage.set resource_id, to_xml
    end
    def delete
      property_storage.delete resource_id
    end

    protected

      def protect!(prop, name = prop.name, ns = prop.namespace)
        return unless ns
        raise PropertyProtected if PROTECTED[ns.href].include? name
      end

      def find_node(property, name = property.name, ns = property.namespace)
#        puts "#{ name }: #{ ns.inspect }"
        if ns
          document.root.at_xpath "C:#{ name }", 'C' => ns.href
        else
          document.root.at_xpath name
        end
      end

      def set(property)
        node = find_node property
        node ||= document.root.add_child document.create_element(property.name)

        href = property.namespace.href if property.namespace

        property.namespace_scopes.each do |ns|
          ns = node.add_namespace_definition ns.prefix, ns.href
          node.namespace = ns if ns.href == href
        end
        node.children = property.children

        node
#      rescue => e
#        puts namespaces
#        puts e.backtrace
#        raise
#      ensure
#        puts node
      end
      def remove(property)
        node = find_node property
        node.remove if node

        node
      end

      def fetch(node_name, default = nil)
        node = document.xpath(@query % node_name, 'D' => 'DAV:').first || default
        block_given?? yield(node) : node if node
      end
      def add_property(node_name)
        node = document.create_element("#{ node_name }", 'xmlns:D' => 'DAV')
        document.root.add_child node
        node.namespace = document.root.namespace
        node
      end

  end
end
