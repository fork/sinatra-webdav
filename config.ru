require 'rubygems'
require 'bundler/setup'

use Rack::ShowExceptions
use Rack::Runtime

require "#{ File.dirname __FILE__ }/lib/webdav"
run WebDAV
