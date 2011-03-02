module DAV
  class MemoryStorage < Storage

    attr_accessor :memory

    def initialize(opts = {})
      @prefix = opts.fetch :prefix, ''
      @memory = opts.fetch :memory, Hash.new { |mem, key| mem[key] = {} }
    end
    def scope(opts)
      self.class.new opts.merge(:memory => memory)
    end

    def get(key)
      @memory[@prefix][key]
    end

    def set(key, value)
      @memory[@prefix][key] = value
    end

    def delete(key)
      @memory[@prefix].delete key
    end

    def keys(pattern = nil)
      list = @memory[@prefix].keys
      list.delete_if do |key|
        not File.fnmatch? pattern, key
      end if pattern

      list
    end

  end
end
