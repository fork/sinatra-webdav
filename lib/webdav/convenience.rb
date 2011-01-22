module WebDAV::Convenience

  def no_cache(last_modified = Time.now)
    return 'Expires'       => 'Mon, 26 Jul 1997 05:00:00 GMT',
           'Last-Modified' => last_modified.httpdate,
           'Cache-Control' => 'no-store, no-cache, must-revalidate',
           'Pragma'        => 'no-cache'
  end

  def request_uri
    URI encode_and_escape(request.url)
  end
  def resource
    @resource ||= DAV::Resource.new request_uri
  end
  def destination_uri
    URI encode_and_escape(request.env['HTTP_DESTINATION'])
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

    def encode_and_escape(url)
      url = URI.unescape url unless passenger?

      begin
        url = url.encode 'utf-8'
        url = URI.escape url
      rescue Encoding::UndefinedConversionError => e
        $stderr.puts e, e.backtrace
        url = url.encode 'utf-8', :undef => :replace, :replace => ''
        retry
      end
    end

end
