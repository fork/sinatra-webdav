module DAV
  module Convenience
    URI = Addressable::URI
    MAPPING = { '0' => 0, '1' => 1, 'infinity' => DAV::Infinity }

    def depth(options)
      exceptions = Array options[:except]

      mapping = MAPPING
      mapping = mapping.inject({}) do |mem, (key, value)|
        mem[key] = value unless exceptions.include? value
        mem
      end unless exceptions.empty?

      mapping.fetch request.env['HTTP_DEPTH'], options[:default]
    end
    def overwrite?
      request.env['HTTP_OVERWRITE'] == 'T'
    end

    def exist?
      resource_storage.member? id
    end
    def collection?
      exist? and properties.collection?
    end
    def display_name
      properties.display_name
    end
    def content_type
      properties.content_type
    end
    def content_length
      properties.content_length
    end
    def entity_tag
      properties.entity_tag
    end
    def last_modified
      properties.last_modified
    end

    def decoded_uri
      URI.unencode uri, URI
    end

    @@opener = {}

    def self.opener(type, opener)
      @@opener[type] = opener || Proc.new
    end
    def open_as(type)
      # FIXME assign @as on initialize
      @as ||= {}

      unless @as.member? type
        # TODO check if content type fits...
        if opener = @@opener[type]
          @as[type] = opener[content]
        else
          @as[type] = nil
        end
      end
      yield @as[type] if @as[type]
    end

    def transcode(url)
      url = URI.unencode url
      url = yield url if block_given?

      URI.encode url
    end
    module_function :transcode

    def to_utf8(url)
      url.encode 'utf-8',
                 :invalid => :replace, :undef => :replace, :replace => ''
    end
    module_function :to_utf8

  end
end
