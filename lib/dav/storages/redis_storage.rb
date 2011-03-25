require 'redis'

module DAV
  class RedisStorage < Storage
    REDIS_OPT_KEYS = [:host, :port, :username, :password, :path]
    include Addressable

    attr_accessor :memory

    def initialize(opts = {})
      @prefix = encode opts.fetch(:prefix, 'DAV')
      @memory = opts[:memory] || begin
        redis_opts = opts.reject { |key, x| REDIS_OPT_KEYS.include? key }
        redis_opts.empty?? Redis.new : Redis.new(redis_opts)
      end
    end

    def scope(opts)
      self.class.new opts.merge(:memory => memory)
    end

    def get(key)
      @memory.hget @prefix, encode(key)
    end

    def set(key, value)
      key = encode key

      unless value.nil?
        @memory.hset @prefix, key, value
      else
        @memory.hdel @prefix, key
      end

      value
    end

    def delete(key)
      key = encode key
      @memory.hget(@prefix, key).tap { |v| @memory.hdel @prefix, key }
    end

    def member?(key)
      @memory.hexists @prefix, encode(key)
    end

    def keys(pattern = nil)
      keys = @memory.hkeys
      keys.map! { |key| decode key }
      keys.select! { |key| File.fnmatch? pattern, key } if pattern

      keys
    end

    protected

      def encode(key)
        URI.encode_component key, URI::CharacterClasses::PATH
      end
      def decode(key)
        URI.unencode key
      end

  end
end
