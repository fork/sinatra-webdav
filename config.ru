require 'rubygems'
require 'bundler/setup'

use Rack::ShowExceptions
use Rack::Runtime

require "#{ File.dirname __FILE__ }/lib/webdav"
require "#{ File.dirname __FILE__ }/lib/put"
run WebDAV
