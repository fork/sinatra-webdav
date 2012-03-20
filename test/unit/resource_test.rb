require File.expand_path('../../teststrap', __FILE__)

storage = DAV::MemoryStorage.new
DAV.PropertyStorage = storage.scope :prefix => 'PROPERTIES'
DAV.ResourceStorage = storage.scope :prefix => 'RESOURCES'
DAV.RelationStorage = storage.scope :prefix => 'RELATIONS'

context 'DAV::Resource' do
  setup { DAV::Resource }

  context 'instance' do
    setup { topic.new Request.new('http://example.org/resource') }

    asserts '#uri' do
      topic.uri
    end.kind_of Addressable::URI

    asserts '#properties' do
      topic.properties
    end.kind_of DAV::Properties

    # TODO ...

  end

end
