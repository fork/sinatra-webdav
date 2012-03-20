require File.expand_path('../../teststrap', __FILE__)

module MemoryStorageTest
  class KeyMaster < Struct.new(:results)
    def [](ns)
      results[ns] ||= {}
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
          @storage = {}
          storage.memory = KeyMaster.new(@storage)
        end
      end

      asserts 'set key' do
        topic.set 'key', 'value'
        @storage['PREFIX-']['key']
      end.equals 'value'

      asserts 'get key' do
        topic.get 'key'
      end.equals 'value'

      asserts 'delete key' do
        topic.delete 'key'
        @storage['PREFIX-']['key']
      end.nil

    end

  end
end