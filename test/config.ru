ENV['RACK_ENV'] = 'test'

use Rack::CommonLogger
use Rack::ShowExceptions

require 'rubygems'
require 'bundler'
Bundler.require

require File.expand_path('../../lib/webdav', __FILE__)

DAV::Resource.backend = DAV::FileBackend
DAV::Resource.root = File.expand_path('../htdocs', __FILE__)

WebDAV::Base.before { puts request.env['HTTP_X_LITMUS'] }
run WebDAV::Base
