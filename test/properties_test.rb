root = File.expand_path '..', __FILE__
require "#{ root }/teststrap"

Example  = Struct.new :patch, :find
EXAMPLES = Hash.new { |examples, section| examples[section] = Example.new }

EXAMPLES['9.2.2'].patch = <<-XML
<?xml version="1.0" encoding="utf-8" ?>
<D:propertyupdate xmlns:D="DAV:" xmlns:Z="http://ns.example.com/standards/z39.50/">
  <D:set>
    <D:prop>
      <Z:Authors>
        <Z:Author>Jim Whitehead</Z:Author>
        <Z:Author>Roy Fielding</Z:Author>
      </Z:Authors>
    </D:prop>
  </D:set>
  <D:remove>
    <D:prop><Z:Copyright-Owner/></D:prop>
  </D:remove>
</D:propertyupdate>
XML

# FIXME default attributes missing...
EXAMPLES['9.2.2'].find = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<multistatus xmlns="DAV:">
  <response>
    <href>http://example.org%s</href>
    <propstat>
      <prop>
        <Authors xmlns:Z="http://ns.example.com/standards/z39.50/">
        <Z:Author>Jim Whitehead</Z:Author>
        <Z:Author>Roy Fielding</Z:Author>
      </Authors>
      </prop>
    </propstat>
  </response>
</multistatus>
XML

DAV::Resource.backend = DAV::FileBackend # maybe we add a redis backend...
DAV::Resource.root = File.join root, 'public'

FileUtils.rmtree File.join(root, 'public')
FileUtils.mkpath File.join(root, 'public')

context "sinatra-webdav" do

  setup do
    @app = WebDAV::Base
  end

  asserts "copied resource properties" do
    put '/test', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
    proppatch '/test', StringIO.new(EXAMPLES['9.2.2'].patch)
    copy '/test', {}, 'HTTP_DESTINATION' => 'test2', 'HTTP_DEPTH' => '1'
    propfind '/test2'
    properties_find = last_response.body
    delete '/test'
    delete '/test2'
    properties_find
  end.equals EXAMPLES['9.2.2'].find % '/test2'

  asserts "copied descendants properties" do
    mkcol '/test/'
    put '/test/test', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
    proppatch '/test/test', StringIO.new(EXAMPLES['9.2.2'].patch)
    copy '/test/', {}, 'HTTP_DESTINATION' => '/test2/', 'HTTP_DEPTH' => 'infinity'
    propfind '/test2/test'
    properties_find = last_response.body
    delete '/test/'
    delete '/test2/'
    properties_find
  end.equals EXAMPLES['9.2.2'].find % '/test2/test'

end
