module DAV
  class Children < Struct.new(:parent)
    include DAV
    attr_reader :paths

    SEPARATOR = "\n"

    def initialize(parent)
      super parent
      load_paths
    end

    def store
      return unless changed?

      unless @paths.empty?
        relation_storage.set parent.id, @paths.join(SEPARATOR)
      else
        relation_storage.delete parent.id
      end

      reset!
    end

    def add(child)
      child.tap { |x| @paths << child.uri.path }
      changed!
      self
    end
    def remove(child)
      child.tap { |x| @paths.delete child.uri.path }
      changed!
      self
    end

    def each
      if block_given?
        @paths.each { |path| yield parent.join(path) }
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

      def load_paths
        string   = relation_storage.get parent.id
        string ||= ''

        @paths = string.split(SEPARATOR).map { |uri| URI.parse(uri).path }
      end

  end
end
