require 'addressable/uri'
require 'nokogiri'
require 'sinatra/base'

module WebDAV

end

require_relative "dav"
require_relative "webdav/verbs"
require_relative "webdav/statuses"
require_relative "webdav/convenience"
require_relative "webdav/base"

if ENV['RACK_ENV'] == 'test'
  require_relative "litmus"
else
  module Litmus
    # noop
    def self.puts(*args) end
  end
end
