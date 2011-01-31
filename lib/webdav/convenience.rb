module WebDAV::Convenience

  def no_cache(last_modified = Time.now)
    return 'Expires'       => 'Mon, 26 Jul 1997 05:00:00 GMT',
           'Last-Modified' => last_modified.httpdate,
           'Cache-Control' => 'no-store, no-cache, must-revalidate',
           'Pragma'        => 'no-cache'
  end

  def request_uri
    Addressable::URI.parse transcode(request.url) { |url| encode_utf8 url }
  end
  def resource
    @resource ||= DAV::Resource.new request_uri, self
  end
  def destination_uri
    http_destination = request.env['HTTP_DESTINATION']
    Addressable::URI.parse encode_utf8(http_destination)
  end
  def destination
    @destination ||= resource.join destination_uri
  end

  MAPPING = { '0' => 0, '1' => 1, 'infinity' => DAV::Infinity }
  def depth(options)
    mapping = MAPPING
    exceptions = Array options[:except]

    mapping = mapping.inject({}) do |mem, (key, value)|
      mem[key] = value unless exceptions.include? value
      mem
    end unless exceptions.empty?

    mapping.fetch request.env['HTTP_DEPTH'], options[:default]
  end
  def overwrite?
    request.env['HTTP_OVERWRITE'] == 'T'
  end

  protected

    def passenger?
      Object.const_defined? :PhusionPassenger and
      request.env.member? 'PASSENGER_ENVIRONMENT'
    end

    def transcode(url)
      url = Addressable::URI.unencode url unless passenger?
      url = yield url if block_given?

      Addressable::URI.encode url
    end

    def encode_utf8(url)
      url.encode 'utf-8',
                 :invalid => :replace, :undef => :replace, :replace => ''
    end

end
