require 'rubygems'
require 'bundler/setup'
Bundler.require

use Rack::CommonLogger
use Rack::ShowExceptions
use Rack::Runtime

root = File.dirname __FILE__
require "#{ root }/lib/webdav"
require "#{ root }/application"

run Application
