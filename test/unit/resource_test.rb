ROOT = File.expand_path '../..', __FILE__
require "#{ ROOT }/teststrap"

storage = DAV::MemoryStorage.new
DAV.PropertyStorage = storage.scope :prefix => 'PROPERTIES'
DAV.ResourceStorage = storage.scope :prefix => 'RESOURCES'
DAV.RelationStorage = storage.scope :prefix => 'RELATIONS'

context "DAV::Resource" do
  setup { DAV::Resource }

  context "object" do
    setup { topic.new URI.parse 'http://example.org/resource' }

    asserts '#uri' do
      topic.uri
    end.kind_of Addressable::URI

    asserts '#properties' do
      topic.properties
    end.kind_of DAV::Properties

    # TODO ...

  end

end
