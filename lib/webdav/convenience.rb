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

end
