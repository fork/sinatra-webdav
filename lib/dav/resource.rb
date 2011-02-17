module DAV
  class Resource < Struct.new(:uri, :app)
    include EventHandling

    URI = Addressable::URI

    class LogMethod < Struct.new(:method)
      def call(resource)
        $stderr.puts "#{ method } #{ resource }"
      end
    end

    %w[ get put mkcol delete copy move ].each do |method|
      before method.to_sym, LogMethod.new(method.upcase)
    end if $-d

    extend Module.new { attr_reader :backend }

    def self.backend=(backend)
      include @backend = backend
      # RADAR overwrite supported methods?
    end

    alias resource class

    def type
      Rack::Mime.mime_type File.extname(uri.path)
    end

    def open(*args)
      return super if resource.backend.supports? :open
      raise NoMethodError
    end
    def children
      @children ||= super
    end
    def descendants
      collection = []

      children_resources = children
      while child = children_resources.shift
        collection << child
        children_resources.concat child.children if child.collection?
      end

      collection
    end
    def ancestors
      collection = []
      
      parent_resource = parent
      until parent_resource == parent_resource.parent
        collection << parent_resource
        parent_resource = parent_resource.parent
      end

      collection
    end
    def collection?
      uri.path =~ %r'/$'
    end
    def mkcol
      around :mkcol do
        super
      end
    end
    def delete(header = {})
      around :delete do
        children.each { |child| child.delete header } if collection?
        super
      end
    end

    def decoded_uri
      @decoded_uri ||= URI.unencode uri, URI
    end

    def join(href)
      encoded_uri = URI.encode decoded_uri.join(href), URI
      resource.new encoded_uri, app
    end
    def parent
      @parent ||= join "#{ File.dirname uri.path }/".sub('//', '/')
    end
    def display_name
      File.basename uri.path
    end
    def ==(other)
      resource === other and uri == other.uri
    end
    def exist?
      return super if resource.backend.supports? :exist?
      return true if parent == self
      parent.collection? and parent.children.include? self
    end
    def properties=(properties)
      super properties
    end
    def properties
      super
    end
    def get
      around(:get) { open }
    end
    def put(source_io)
      around :put do
        source_io.binmode if source_io.respond_to?(:binmode)
        open 'wb' do |io|
          blocksize = io.stat.blksize
          blocksize = 4096 unless blocksize and blocksize > 0

          while data = source_io.read(blocksize)
            io << data
          end
        end
      end
    end
    def copy(destination, depth = Infinity)
      around :copy do
        destination.delete if destination.exist?

        if not collection?
          destination.put get
        else
          destination.mkcol

          if depth > 0
            children do |child|
              basename = child.display_name
              basename << '/' if child.collection?

              child.copy destination.join(basename), depth - 1
            end
          end
        end
        destination.properties = properties
      end
    end
    def move(destination, depth = Infinity)
      around :move do
        copy destination, depth
        delete
      end
    end

    def to_s
      uri.to_s
    end

  end
end
