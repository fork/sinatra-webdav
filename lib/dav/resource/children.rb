module DAV
  class Children < Struct.new(:parent)
    include DAV

    def initialize(parent)
      super parent
      @changes = []
    end

    def write
      storage = relation_storage.memory

      # TODO Implement a sync class to support locking with other storages
      # TODO make this work on resource level
      if storage.class.name == 'Redis'
        # RADAR This is just a hotfix!
        return write_optimistic(storage)
      else
        update get_data
        return true
      end
    end

    def store
      return unless changed?
      sleep 0.001 until write

      reset!

      return true
    end

    def add(child)
      @changes << [child.decoded_uri.path, :add]
      self
    end
    def remove(child)
      @changes << [child.decoded_uri.path, :remove]
      self
    end

    def include?(resource)
      get_data =~ /^#{ Regexp.escape resource.decoded_uri.path }\n/
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
        # Ruby does not create an empty element if the last character is the
        # separator!
        get_data.split "\n"
      end
      def update(data)
        @changes.each do |(path, change)|
          path_rx = /^#{ Regexp.escape path }\n/
          case change
          when :add
            data << "#{ path }\n" unless data =~ path_rx
          when :remove
            data.sub! path_rx, ''
          end
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
        not @changes.empty?
      end
      def reset!
        @changes.clear
      end

  end
end
