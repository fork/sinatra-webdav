module DAV
  class Children < Struct.new(:parent)
    include DAV
    attr_reader :uris

    SEPARATOR = "\n"

    def initialize(parent)
      super parent
      load_uris
    end

    def store
      return unless changed?

      unless @uris.empty?
        relation_storage.set parent.id, @uris.join(SEPARATOR)
      else
        relation_storage.delete parent.id
      end

      reset!
    end

    def add(child)
      child.tap { |x| @uris << child.uri }
      changed!
      self
    end
    def remove(child)
      child.tap { |x| @uris.delete child.uri }
      changed!
      self
    end

    def each
      if block_given?
        @uris.each { |uri| yield parent.join(uri) }
      else
        Enumerator.new self, :each
      end
    end

    protected

      attr_reader :changed
      alias changed? changed
      def changed!
        @changed = true
      end
      def reset!
        @changed = false
      end

      def load_uris
        string   = relation_storage.get parent.id
        string ||= ''

        @uris = string.split(SEPARATOR).map { |uri| URI.parse uri }
      end

  end
end
