ROOT = File.expand_path '../..', __FILE__
require "#{ ROOT }/teststrap"

class KeyMaster < Struct.new(:results)
  def [](key)
    results[:get] << key
  end
  def []=(key, value)
    results[:set] << key
  end
  def delete(key)
    results[:delete] << key
  end
end

context "DAV::MemoryStorage" do
  setup { DAV::MemoryStorage }

  context "without prefix" do
    setup { topic.new }

    asserts 'get on non-existing key' do
      topic.get 'key'
    end.nil

    asserts 'delete on non-existing key' do
      topic.delete 'key'
    end.nil

    asserts 'set on key' do
      topic.set 'key', 'value-1'
    end.equals 'value-1'

    asserts 'get on existing key' do
      topic.set 'key', 'value-2'
      topic.get 'key'
    end.equals 'value-2'

    asserts 'get a nil value' do
      topic.set 'key', nil
      topic.get 'key'
    end.nil

    asserts 'delete on existing key' do
      topic.set 'key', 'value-3'
      topic.delete 'key'
    end.equals 'value-3'

    asserts 'get on deleted key' do
      topic.get 'key'
    end.nil

  end
  context "with prefix" do
    setup do
      topic.new(:prefix => 'PREFIX-').tap do |storage|
        @storage = Hash.new { |h, k| h[k] = [] }
        storage.memory = KeyMaster.new(@storage)
      end
    end

    asserts 'get key-0' do
      topic.get 'key-0'
      @storage[:get].last
    end.equals 'PREFIX-key-0'

    asserts 'delete key-1' do
      topic.delete 'key-1'
      @storage[:delete].last
    end.equals 'PREFIX-key-1'

    asserts 'set key-2' do
      topic.set 'key-2', 'value-1'
      @storage[:set].last
    end.equals 'PREFIX-key-2'

  end

end
