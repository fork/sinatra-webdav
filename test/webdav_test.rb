require 'rubygems'
require 'bundler/setup'

require File.expand_path('../../lib/webdav', __FILE__)
Bundler.require :test

context 'WebDAV' do

  setup { Rack::Test::Session.new Rack::MockSession.new(WebDAV) }

end
