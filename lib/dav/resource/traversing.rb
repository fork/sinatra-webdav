module DAV
  module Traversing
    URI = Addressable::URI

    def join(href)
      encoded_uri = URI.encode URI.unencode(uri, URI).join(href), URI
      self.class.new request, encoded_uri
    end
    def parent
      @parent ||= if uri.path != '/'
        join "#{ File.dirname uri.path }/".sub('//', '/')
      else
        self 
      end
    end
    def ancestors
      return [] if uri.path == '/'
      parent.ancestors << parent
    end
    def children
      @children ||= Children.new self
    end
    def descendants
      children.to_a.tap { |list| list.concat child.descendants }
    end

    def destination
      @destination ||= begin
        http_destination = request.env['HTTP_DESTINATION']
        uri = URI.parse to_utf8(http_destination)

        join uri
      end
    end
    def destination=(resource)
      @destination = resource
    end

  end
end
