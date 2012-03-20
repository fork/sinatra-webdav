require 'rubygems'
require 'bundler'
begin
  Bundler.require(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require File.expand_path('../../lib/sinatra-webdav', __FILE__)

module Example
  ROOT = File.expand_path '../examples', __FILE__
  def self.open(basename)
    File.open File.join(ROOT, "#{ basename }.xml") do |file|
      yield file
    end
  end
end

ROOT = File.expand_path '..', __FILE__

module PropertyReader
  def length
    value = at_css('getcontentlength').text
    value.strip!

    Integer value
  end
  def type
    value = at_css('getcontenttype').text
    value.strip!

    value
  end
  def collection?
    not css('resourcetype collection').empty?
  end
end

class Riot::Situation

  def app; @app; end
  Rack::Test::Session.send :public, :env_for
  Rack::Test::Methods.send :def_delegators, :current_session, :env_for
  include Rack::Test::Methods
  include Addressable

  extend Forwardable
  def_delegators :current_session, :env_for, :process_request

  def multi
    xml = Nokogiri::XML last_response.body
    xml.decorators(Nokogiri::XML::Node) << PropertyReader

    responses = xml.css 'response'

    responses.each do |response|
      yield response
    end if block_given?

    responses
  end

  count = 0
  COUNTER = -> { count += 1; count - 1 }

  def count
    COUNTER.call
  end

  def temporary_path(*args)
    opts = Hash === args.last ? args.pop : {}

    parent = opts[:parent] || '/'
    parent << '/' unless parent =~ %r'/$'

    path = "#{ parent }#{ opts[:basename] || 'test' }#{ count }"
    path << '/' if opts[:collection]

    if block_given?
      result = yield path
      delete path

      return result
    else
      path
    end
  end

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
