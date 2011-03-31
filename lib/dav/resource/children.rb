require 'set'

module DAV
  class Children < Struct.new(:parent)
    include DAV

    SEPARATOR = "\n"
    FINDER    = "^%s#{ SEPARATOR }"

    def initialize(parent)
      super parent
      @adds, @removes = [], []
    end

    def write
      storage = relation_storage.memory

      # TODO support optimistic locking with other storage engines, too
      return write_optimistic(storage) if storage.class.name == 'Redis'

      update get_data
      return true
    end

    def store
      return unless changed?
      sleep 0.001 until write

      reset!

      return true
    end

    def add(child)
      @adds << child.decoded_uri.path
      self
    end
    def remove(child)
      @removes << child.decoded_uri.path
      self
    end

    def include?(resource)
      paths.include? resource.decoded_uri.path
    end

    def each
      if block_given?
        paths.each { |path| yield parent.join(path) }
      else
        Enumerator.new self, :each
      end
    end

    def uris
      base = parent.uri
      paths.map { |path| base.join path }
    end

    protected

      def get_data
        relation_storage.get(parent.id) || ''
      end
      def paths
        collection = get_data.split SEPARATOR
        collection.pop

        collection
      end
      def update(data)
        unless @removes.empty?
          esc_paths = @removes.map { |path| Regexp.escape path }
          data.gsub!(/#{ FINDER % "(?:#{ esc_paths.join '|' })" }/, '')
        end
        @adds.each do |path|
          next if data =~ /#{ FINDER % Regexp.escape(path) }/
          data << "#{ path }\n"
        end

        unless data.empty?
          relation_storage.set parent.id, data
        else
          relation_storage.delete parent.id
        end
      end
      def write_optimistic(storage)
        storage.watch 'relations'
        data = get_data
        return storage.multi { update data }
      end

      def changed?
        not @adds.empty? && @removes.empty?
      end
      def reset!
        @adds.clear
        @removes.clear
      end

  end
end
