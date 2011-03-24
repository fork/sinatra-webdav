require 'set'

module DAV
  class Children < Struct.new(:parent)
    include DAV

    SEPARATOR = "\n"

    def initialize(parent)
      super parent
      @adds, @removes = [], []
    end

    def modify_set(set)
      @removes.each do |child|
        set.delete_if { |uri| uri == child.decoded_uri }
      end
      @adds.each { |child| set.add child.decoded_uri }

      unless set.empty?
        relation_storage.set parent.id, set.to_a.join(SEPARATOR)
      else
        relation_storage.delete parent.id
      end
    end

    def write_optimistic(storage)
      storage.watch 'relations'
      set = uris
      return storage.multi { modify_set set }
    end

    def write
      storage = relation_storage.memory

      # TODO support optimistic locking with other storage engines, too
      return write_optimistic(storage) if storage.class.name == 'Redis'

      modify_set uris
      return true
    end

    def store
      return unless changed?
      sleep 0.001 until write

      reset!

      return true
    end

    def add(child)
      @adds << child
      self
    end
    def remove(child)
      @removes << child
      self
    end

    def include?(resource)
      uris.include? parent.uri.join(resource.decoded_uri)
    end

    def each
      if block_given?
        uris.each { |uri| yield parent.join(uri.path) }
      else
        Enumerator.new self, :each
      end
    end

    def uris
      str   = relation_storage.get parent.id
      str ||= ''
      base = parent.uri

      Set.new str.split(SEPARATOR).map { |uri| base.join URI.parse(uri).path }
    end

    protected

      def changed?
        not @adds.empty? && @removes.empty?
      end
      def reset!
        @adds.clear
        @removes.clear
      end

  end
end
