module WebDAV::Convenience

  def no_cache(last_modified = Time.now)
    return 'Expires'       => 'Mon, 26 Jul 1997 05:00:00 GMT',
           'Last-Modified' => last_modified.httpdate,
           'Cache-Control' => 'no-store, no-cache, must-revalidate',
           'Pragma'        => 'no-cache'
  end

  def resource
    @resource ||= DAV::Resource.new request
  end

  def responder
    yield @responder if defined? @responder and block_given?

    @responder ||= if block_given?
      DAV::Responder.new(request, &Proc.new)
    else
      DAV::Responder.new request
    end
  end

end
