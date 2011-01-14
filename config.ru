require 'rubygems'
require 'bundler/setup'

use Rack::ShowExceptions
use Rack::Runtime

root = File.dirname __FILE__

Bundler.require
require "#{ root }/lib/sinatra/templates/slim"
require "#{ root }/lib/plupload"
require "#{ root }/lib/dav"
require "#{ root }/lib/models"
require "#{ root }/lib/uploader"
require "#{ root }/lib/verbs"

require "#{ root }/config"

require "#{ root }/lib/webdav"
run WebDAV
