module WebDAV
end

root = File.dirname __FILE__
require "#{ root }/dav"
require "#{ root }/webdav/verbs"
require "#{ root }/webdav/statuses"
require "#{ root }/webdav/convenience"
require "#{ root }/webdav/base"
