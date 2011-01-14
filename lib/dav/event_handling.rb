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

    class Handler < Struct.new(:pattern_or_expression, :unit)
      def matches?(uri)
        case pattern_or_expression
        when String then File.fnmatch? pattern_or_expression, uri.path
        when Regexp then pattern_or_expression =~ uri.path
        end
      end
      def call(resource)
        unit.call resource if matches? resource.uri
      end
    end

    module ClassMethods
      attr_accessor :event_manager

      def before(method_sym, pattern, unit = nil)
        unit.respond_to? :call or
        unit = Symbol === unit ? method(unit) : Proc.new

        event_manager.before method_sym, Handler.new(pattern, unit)

        self
      end
      def after(method_sym, pattern, unit = nil)
        unit.respond_to? :call or
        unit = Symbol === unit ? method(unit) : Proc.new

        event_manager.after method_sym, Handler.new(pattern, unit)

        self
      end

    end

    def self.included(base)
      base.extend ClassMethods
      base.event_manager = EventManager.new
    end

    protected

      def around(method)
        resource.event_manager[method].before.
        each { |handler| handler.call self }

        result = yield

        resource.event_manager[method].after.
        each { |handler| handler.call self }

        result
      end

  end
end
