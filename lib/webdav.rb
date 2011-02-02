require 'addressable/uri'
require 'nokogiri'
require 'sinatra/base'

module WebDAV
end

root = File.expand_path '..', __FILE__
require "#{ root }/dav"
require "#{ root }/webdav/verbs"
require "#{ root }/webdav/statuses"
require "#{ root }/webdav/convenience"
require "#{ root }/webdav/base"
