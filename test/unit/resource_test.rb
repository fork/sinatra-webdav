require File.expand_path('../../teststrap', __FILE__)

storage = DAV::MemoryStorage.new
DAV.PropertyStorage = storage.scope :prefix => 'PROPERTIES'
DAV.ResourceStorage = storage.scope :prefix => 'RESOURCES'
DAV.RelationStorage = storage.scope :prefix => 'RELATIONS'

context 'DAV::Resource' do
  setup { DAV::Resource }

  asserts 'Forwarded URI with differing host' do
    env = env_for 'http://example.org/resource', 'HTTP_X_FORWARDED_HOST' => 'host.local'
    resource = topic.new Sinatra::Request.new(env)
    resource.uri.to_s
  end.equals 'http://host.local/resource'

  context 'instance' do
    setup { topic.new Sinatra::Request.new(env_for('http://example.org/resource', {})) }

    asserts '#uri' do
      topic.uri
    end.kind_of Addressable::URI

    asserts '#properties' do
      topic.properties
    end.kind_of DAV::Properties

    # TODO ...

  end

end
