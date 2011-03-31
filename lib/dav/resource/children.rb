require 'set'

module DAV
  class Children < Struct.new(:parent)
    include DAV

    SEPARATOR = "\n"
    FINDER = "^[a-z]+:\/\/[^\/]+%s#{ SEPARATOR }"

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
      str  = get_data
      base = parent.uri

      Set.new str.split(SEPARATOR).map { |uri| base.join URI.parse(uri).path }
    end

    protected

      def get_data
        relation_storage.get(parent.id) || ''
      end
      def update(data)
        unless @removes.empty?
          paths = @removes.map { |child| Regexp.escape child.decoded_uri.path }
          data.gsub!(/#{ FINDER % "(?:#{ paths.join '|' })" }/, '')
        end

        @adds.each do |child|
          decoded_uri = child.decoded_uri
          data =~ /#{ FINDER % Regexp.escape(decoded_uri.path) }/ or
          data << "#{ decoded_uri }#{ SEPARATOR }"
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
