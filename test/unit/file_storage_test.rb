ROOT = File.expand_path '../..', __FILE__
require "#{ ROOT }/teststrap"

context "DAV::FileStorage" do
  URI = Addressable::URI

  root = File.join Dir.tmpdir

  key = 'example.com/foo bar/baz'
  encoded_key = URI.encode_component key, URI::CharacterClasses::PATH

  path = File.join key.split('/')

  setup { DAV::FileStorage }

  context "without prefix" do
    setup { topic.new }

    asserts 'get on non-existing key' do
      topic.get key
    end.nil

    asserts 'delete on non-existing key' do
      topic.delete key
    end.nil

    asserts '@memory' do
      topic.memory
    end.kind_of Pathname

    asserts 'set on key' do
      topic.set key, 'value-1'
    end.equals 'value-1'

    asserts 'stores values in files in tmp dir' do
      File.file? File.join(root, 'file_storage.rb', path)
    end

    asserts 'get on existing key' do
      topic.set key, 'value-2'
      topic.get key
    end.equals 'value-2'

    asserts '#keys' do
      topic.keys
    end.equals [key]

    denies '#keys with pattern "/foo"' do
      topic.keys '/foo'
    end.any
    asserts '#keys with pattern "example.com/*"' do
      topic.keys 'example.com/*'
    end.equals [key]

    asserts 'delete on existing key' do
      topic.set key, 'value-3'
      topic.delete key
    end.equals 'value-3'

    asserts 'get a nil value' do
      topic.set key, nil
      topic.get key
    end.nil

    asserts 'get on deleted key' do
      topic.get key
    end.nil

  end

  context "with prefix" do
    setup do
      topic.new :prefix => 'DELETE-ME'
    end

    asserts 'creates DELETE-ME dir in current working dir' do
      full_path = File.join Dir.tmpdir, 'DELETE-ME'

      File.directory?(full_path).tap do |exist|
        FileUtils.rmtree full_path if exist
      end
    end

  end

  context "with root" do
    setup { topic.new :root => File.join(root, 'DELETE-ME') }

    asserts 'creates DELETE-ME-TOO dir in root' do
      full_path = File.join root, 'DELETE-ME'

      File.directory?(full_path).tap do |exist|
        FileUtils.rmtree full_path if exist
      end
    end

  end

end
