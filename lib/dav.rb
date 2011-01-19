module DAV

  autoload :FileBackend, File.expand_path('../dav/file_backend.rb', __FILE__)
  Infinity = 1.0 / 0

end

require "#{ File.dirname __FILE__ }/dav/event_handling"
require "#{ File.dirname __FILE__ }/dav/resource"
require "#{ File.dirname __FILE__ }/dav/properties"
