ENV['RACK_ENV'] = 'test'

use Rack::CommonLogger
use Rack::ShowExceptions

require 'rubygems'
require 'bundler'
Bundler.require

require File.expand_path('../../lib/webdav', __FILE__)

storage = DAV::MemoryStorage.new
DAV.PropertyStorage = storage.scope :prefix => 'PROPERTIES'
DAV.ResourceStorage = storage.scope :prefix => 'RESOURCES'
DAV.RelationStorage = storage.scope :prefix => 'RELATIONS'

DAV::Base.mkroot 'localhost'

WebDAV::Base.before { puts request.env['HTTP_X_LITMUS'] }
run WebDAV::Base
