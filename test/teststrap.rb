require 'rubygems'
require 'bundler'
begin
  Bundler.require(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'riot'
require File.expand_path('../../lib/sinatra-webdav', __FILE__)

require 'riot'
class Riot::Situation

  def app; @app; end
  include Rack::Test::Methods

  extend Forwardable
  def_delegators :current_session, :env_for, :process_request

  def copy(uri, params = {}, env = {}, &block)
    env = env_for(uri, env.merge(:method => "COPY", :params => params))
    process_request(uri, env, &block)
  end
  def move(uri, params = {}, env = {}, &block)
    env = env_for(uri, env.merge(:method => "MOVE", :params => params))
    process_request(uri, env, &block)
  end
  def propfind(uri, params = {}, env = {}, &block)
    env = env_for(uri, env.merge(:method => "PROPFIND", :params => params))
    process_request(uri, env, &block)
  end
  def proppatch(uri, params = {}, env = {}, &block)
    env = env_for(uri, env.merge(:method => "PROPPATCH", :params => params))
    process_request(uri, env, &block)
  end
  def mkcol(uri, params = {}, env = {}, &block)
    env = env_for(uri, env.merge(:method => "MKCOL", :params => params))
    process_request(uri, env, &block)
  end

end
