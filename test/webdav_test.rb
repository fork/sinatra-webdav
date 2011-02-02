require 'teststrap'

context "sinatra-webdav" do

  setup { Rack::Test::Session.new Rack::MockSession.new(WebDAV) }

  asserts "i'm a failure :(" do
    topic
  end

end
