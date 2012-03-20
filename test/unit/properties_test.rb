require File.expand_path('../../teststrap', __FILE__)

storage = DAV::MemoryStorage.new
DAV.PropertyStorage = storage.scope :prefix => 'PROPERTIES'

class Resource < Struct.new(:id)
  def uri
    Addressable::URI.parse "http://#{ id }"
  end
  def properties
    @properties ||= DAV::Properties.new self
  end
end
FirstResource   = Resource.new 'example.org/first'
SecondResource  = Resource.new 'example.org/second'
FakeCollection  = Resource.new 'example.org/col/'

# Properties is an Enumerator
# Properties object emits Property objects
# Properties is bound to Resource or URI
context "DAV::Properties" do

  namespaces = {
    'D' => 'DAV:',
    'Z' => 'http://ns.example.com/standards/z39.50/'
  }

  setup { DAV::Properties }

  asserts('is Enumerable') { topic < Enumerable }

  context "when blank" do
    setup { FirstResource.properties }

    asserts('#resource_id') { topic.resource_id }.kind_of String
    asserts('#each without block') { topic.each }.kind_of Enumerator

    asserts '#patch D:Authors' do
      DAV::Responder.new do |responder|
        Example.open('proppatch-authors') do |patch|
          responder.respond_to FirstResource.uri do |response|
            topic.patch patch, response
          end
        end
      end
      topic.store

      properties = Resource.new('example.org/first').properties
      nodes = properties.document.at_xpath '/D:prop/Z:Authors', namespaces

      nodes.xpath('Z:Author', namespaces).map { |child| child.text } if nodes
    end.equals ['Jim Whitehead', 'Roy Fielding']
  end

  context "object with properties set" do

    now = Time.parse Time.now.httpdate

    properties = {
      :creation_date    => now,
      :display_name     => 'FakeResource',
      :content_language => 'en-US',
      :content_length   => 200,
      :content_type     => 'text/lorem',
      :entity_tag       => '1234-81dc9bdb52d04dc20036dbd8313ed055',
      :last_modified    => now,
      :lock_discovery   => '',
      :resource_type    => 'collection',
      :supported_lock   => ''
    }

    setup do
      topic.new(FirstResource).tap do |instance|
        properties.each do |property, value|
          instance.respond_to? property and
          instance.send :"#{ property }=", value
        end
      end
    end

    properties.each do |property, value|
      asserts("the result of calling ##{ property }") { topic.send property }.
      equals value
    end

    asserts('#collection? returns true') do
      topic.collection?
    end

    asserts('#copy copies properties') do
      FirstResource.properties.copy SecondResource.properties
      FirstResource.properties.to_xml == SecondResource.properties.to_xml
    end

    denies('#store does not write anything') do
      topic.store
      topic.to_xml.nil? or topic.to_xml.empty?
    end

    asserts('#store writes its xml into the property storage') do
      xml = DAV.PropertyStorage.get FirstResource.id
      topic.to_xml == xml
    end

    asserts('#to_xml returns xml presentation of D:prop node') do
      doc = Nokogiri::XML topic.to_xml
      doc.at_css 'D|prop', 'D' => 'DAV:'
    end

    node_names = %w[
      creationdate
      displayname
      getcontentlanguage
      getcontentlength
      getcontenttype
      getetag
      getlastmodified
      lockdiscovery
      resourcetype
      supportedlock
    ]
    asserts('a collection properties not called by #each') do
      topic.each do |node_name, node_content|
        node_names.delete node_name
      end
      node_names
    end.empty

    asserts('#find D:displayname') do
      xml = DAV::Responder.new do |responder|
        responder.respond_to FirstResource.uri do |response|
          Example.open 'propfind-displayname' do |example|
            topic.find example, response
          end
        end
      end.to_xml

      path = '/D:multistatus/D:response/D:propstat/D:prop/D:displayname'

      displayname = Nokogiri::XML(xml).at_xpath(path, 'D' => 'DAV:')
      displayname.content if displayname
    end.equals 'FakeResource'

    asserts('#find D:allprop') do
      xml = DAV::Responder.new do |responder|
        responder.respond_to FirstResource.uri do |response|
          Example.open('propfind-allprop') do |example|
            topic.find example, response
          end
        end
      end.to_xml

      path = '/D:multistatus/D:response/D:propstat/D:prop/D:*'

      not Nokogiri::XML(xml).xpath(path, 'D' => 'DAV:').empty?
    end

    asserts('#find D:propname') do
      xml = DAV::Responder.new do |responder|
        responder.respond_to FirstResource.uri do |response|
          Example.open('propfind-propname') do |example|
            topic.find example, response
          end
        end
      end.to_xml

      path = '/D:multistatus/D:response/D:propstat/D:prop/D:*'

      not Nokogiri::XML(xml).xpath(path, 'D' => 'DAV:').empty?
    end

    asserts('properties in storage after #delete') do
      topic.delete
      DAV.PropertyStorage.get FirstResource.id
    end.nil

  end

end
