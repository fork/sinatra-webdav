require 'zlib'

module DAV
  class Base < Struct.new(:request, :uri)
    include DAV

    include Traversing
    include Actions
    include Convenience
    include Opener

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

        root.store
      end
    end

    def self.new(request, uri = nil)
      if uri.nil?
        # FIXME something is broken here, see warning in litmus
        utf8_url = Convenience.transcode(request.url) do |url|
          Convenience.to_utf8 url
        end
        uri = URI.parse utf8_url

        if request.forwarded?
          scheme = request.env['HTTP_X_FORWARDED_PROTO'] and uri.scheme = scheme
          host   = request.env['HTTP_X_FORWARDED_HOST'] and uri.host = host
          port   = request.env['HTTP_X_FORWARDED_PORT'] and uri.port = port
        # maybe some scripts use Rack::Request,
        #   but this should not be expected,
        #   and we don't care!
        end rescue nil
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

      @id ||= path.join '/'
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
      properties.content_length = @content.to_s.length
      update_etag
    end

    def store_content
      resource_storage.set id, content
    end
    def store
      store_content

      properties.last_modified = Time.now
      properties.store

      parent.children.add self unless parent == self
      parent.children.store
    end
    alias store_all store

    def delete_all
      parent.children.remove(self).store
      properties.delete
      resource_storage.delete id
    end
    def update_etag
      properties.
        entity_tag = content ? "#{ content.length }-#{ checksum }" : nil
    end

    protected

      def checksum
        Zlib.crc32 content
      end

  end
end
