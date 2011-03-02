module DAV
  module PropertyAccessors

    def self.included(base)
      raise RuntimeError, 'This module only extends classes.'
    end

    def property(mapping)
      mapping.each do |method_name, node_name|

        accessor = PropertyAccessor.new(method_name) do |rw|
          rw.instance_eval(&Proc.new) if block_given?
        end

        define_method :"#{ method_name }" do
          fetch(node_name) { |node| accessor.read node }
        end

        define_method :"#{ method_name }=" do |value|
          node = fetch node_name
          node ||= add_property node_name
          accessor.write node, value
        end

      end
    end

    class PropertyAccessor < Struct.new(:property, :extension)

      def initialize(property)
        super property, Module.new
        extend extension

        yield self if block_given?
      end

      def reader(&block)
        extension.module_eval { define_method :read, block }
        self
      end
      def read(node)
        node.content
      end
      def writer(&block)
        extension.module_eval { define_method :write, block }
        self
      end
      def write(node, value)
        node.content = value
      end
    end

  end
end
