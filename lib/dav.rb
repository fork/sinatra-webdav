module DAV
  include Addressable

  Error = Class.new RuntimeError

  Module.new do
    attr_accessor :PropertyStorage, :ResourceStorage, :RelationStorage
  end.tap do |storage_accessors|
    extend storage_accessors
  end

  def passenger?
    Object.const_defined? :PhusionPassenger
  end
  module_function :passenger?

  class Storage
    def reader(key)
      DAV::Reader.new key, self
    end
  end
  class Reader < Struct.new(:key, :storage)
    def length
      read.length
    end
    alias size length
    def each
      yield read
    end
    def read
      @data ||= storage.get key
    end
  end

  Infinity = 1.0 / 0

  def self.included(base)
    #puts base.name
    # def base#storage ...
  end
  def self.extended(base)
    #puts base.name
    # def base#storage ...
  end

  protected

    def property_storage
      DAV.PropertyStorage
    end
    def resource_storage
      DAV.ResourceStorage
    end
    def relation_storage
      DAV.RelationStorage
    end

  load_path = File.expand_path '../dav', __FILE__
#  require "#{ load_path }/event_handling"
  require "#{ load_path }/responder"
  require "#{ load_path }/property_accessors"
  require "#{ load_path }/properties"
  require "#{ load_path }/resource"

  autoload :MemoryStorage, "#{ load_path }/storages/memory_storage.rb"
  autoload :RedisStorage, "#{ load_path }/storages/redis_storage.rb"
  autoload :FileStorage, "#{ load_path }/storages/file_storage.rb"

end
