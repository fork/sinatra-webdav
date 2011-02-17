module DAV
  class EventManager

    Chain = Struct.new :before, :after

    def initialize
      @chains = Hash.new { |mem, name| mem[name] = Chain.new [], [] }
    end

    def [](event_name)
      @chains[event_name]
    end
    def before(event_name, resource_handler)
      @chains[event_name].before.unshift resource_handler
    end
    def after(event_name, resource_handler)
      @chains[event_name].after.push resource_handler
    end

  end

  module EventHandling

    class Filter < Struct.new(:matcher, :unit)

      def initialize(*args)
        super(*args)

        if matcher.respond_to? :matches?
          def self.matches?(uri)
            matcher.matches? uri
          end
        elsif matcher.is_a? String
          def self.matches?(uri)
            File.fnmatch? matcher, uri.path
          end
        elsif matcher.is_a? Regexp
          def self.matches?(uri)
            matcher =~ uri.path
          end
        end
      end

      def matches?(uri)
        true
      end

      def call(resource)
        unit.call resource if matches? resource.uri
      end

    end

    module ClassMethods
      attr_accessor :event_manager

      def before(method_sym, pattern, unit = nil)
        unit, pattern = pattern unless String === pattern or Regexp === pattern

        unless unit.respond_to? :call
          unit = Symbol === unit ? method(unit) : Proc.new
        end

        event_manager.before method_sym, Filter.new(pattern, unit)

        self
      end
      def after(method_sym, pattern, unit = nil)
        unit, pattern = pattern unless String === pattern or Regexp === pattern

        unless unit.respond_to? :call
          unit = Symbol === unit ? method(unit) : Proc.new
        end

        event_manager.after method_sym, Filter.new(pattern, unit)

        self
      end

    end

    def self.included(base)
      base.extend ClassMethods
      base.event_manager = EventManager.new
    end

    protected

      def around(method)
        return false if resource.event_manager[method].before.
                        any? { |handler| handler.call(self) === false }

        return false unless result = yield

        return false if resource.event_manager[method].after.
                        any? { |handler| handler.call(self) === false }

        result
      end

  end
end
