use Rack::CommonLogger
use Rack::ShowExceptions

require 'rubygems'
require 'bundler'
Bundler.require

require File.expand_path('../../lib/webdav', __FILE__)

DAV::Resource.backend = DAV::FileBackend
DAV::Resource.root = File.expand_path('../public', __FILE__)

run WebDAV::Base
