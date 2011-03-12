require 'zlib'

module DAV
  class Base < Struct.new(:request, :uri)
    include DAV

    include Traversing
    include Actions
    include Convenience

    extend Callbacks
    define_callbacks :get, :put, :mkcol, :delete, :copy, :move
    define_callbacks :propfind, :proppatch, :lock, :unlock
    define_callbacks :search

    def self.mkroot(domain, now = Time.now)
      root = new nil, URI.parse("file://#{ domain }/")

      unless root.collection?
        root.content = nil

        root.properties.creation_date = now
        root.properties.display_name  = ''
        root.properties.resource_type = 'collection'

        root.store_all
      end
    end

    def self.new(request, uri = nil)
      uri ||= begin
        # FIXME something is broken here, see warning in litmus
        utf8_url = Convenience.transcode(request.url) do |url|
          Convenience.to_utf8 url
        end

        URI.parse utf8_url
      end

      super request, uri
    end

    def properties
      @properties ||= Properties.new self
    end
    def ==(other)
      Resource === other and uri == other.uri
    end
    def id
      path = uri.path.split '/'
      path.shift if path.first and path.first.empty?
      path.pop if path.last and path.last.empty?

      @id ||= "#{ uri.host }/#{ path.join '/' }"
    end

    def body
      @body = resource_storage.reader id unless defined? @body
      @body
    end
    def content
      @content = collection?? nil : body.read unless defined? @content
      @content
    end
    def content=(content)
      @content = content.nil?? content : content.clone
    end

    def store
      resource_storage.set id, content
    end
    def store_all
      store

      properties.last_modified = Time.now
      properties.store

      parent.children.add self unless parent == self
      parent.children.store
    end
    def delete_all
      parent.children.remove(self).store

      properties.delete

      resource_storage.delete id
    end
    def update_etag
      properties.entity_tag = "#{ content.length }-#{ checksum }"
    end

    protected

      def checksum
        Zlib.crc32 content
      end

  end
end
