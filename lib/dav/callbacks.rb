module DAV
  module Callbacks

    class Filter < Struct.new(:matcher, :unit)

      def initialize(*args)
        super(*args)

        if matcher.respond_to? :matches?
          def self.call(resource, *args)
            unit.call(resource, *args) if matcher.matches? resource
          end
        elsif matcher.is_a? String
          def self.call(resource, *args)
            if File.fnmatch? matcher, resource.uri.path
              unit.call(resource, *args)
            end
          end
        elsif matcher.is_a? Regexp
          def self.call(resource, *args)
            unit.call(resource, *args) if matcher =~ resource.uri.path
          end
        end
      end

      def call(resource, *args)
        unit.call resource, *args
      end

    end

    class Collection

      def initialize(klass)
        @klass  = klass
        @queues = {}
        yield @queues if block_given?
      end

      def add(slot, method_sym, pattern, unit)
        unless String === pattern or Regexp === pattern
          unit, pattern = pattern
        end
        unless unit.respond_to? :call
          unit = Symbol === unit ? method(unit) : Proc.new
        end

        @queues["#{ slot }_#{ method_sym }"] << Filter.new(pattern, unit)
      end

      def register(method_sym)
        @queues["before_#{ method_sym }"] = []
        @queues["after_#{ method_sym }"]  = []
      end
      def run(slot, method_sym, obj, *args)
        @queues["#{ slot }_#{ method_sym }"].
        all? { |callback| callback.call(obj, *args) != false } or cancel!
      end

      def clone
        Collection.new @klass do |qs|
          @queues.each { |k, callbacks| qs[k] = callbacks.clone }
        end
      end

      protected

        def cancel!
          throw :cancel
        end

    end

    attr_reader :callbacks

    def self.extended(base)
      base.instance_variable_set :@callbacks, Collection.new(base)
      base.class_eval do
        def callbacks
          self.class.callbacks
        end
      end
    end
    def inherited(base)
      super base
      base.instance_variable_set :@callbacks, callbacks.clone
    end
    def define_callbacks(*methods)
      methods.each do |method_sym|
        alias_method :"#{ method_sym }_without_callbacks", method_sym
        class_eval <<-RUBY
          def #{ method_sym }(*args)
            catch(:cancel) do
              callbacks.run(:before, :#{ method_sym }, self, *args)
              result = #{ method_sym }_without_callbacks(*args)
              callbacks.run(:after, :#{ method_sym }, self, *args)

              result
            end
          end
        RUBY
        callbacks.register method_sym
      end
    end

    def before(method_sym, pattern = nil, unit = nil, &block)
      callbacks.add :before, method_sym, pattern, unit, &block
      self
    end
    def after(method_sym, pattern = nil, unit = nil, &block)
      callbacks.add :after, method_sym, pattern, unit, &block
      self
    end

  end
end
