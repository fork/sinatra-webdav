module DAV
  module Opener

    DEFAULT_OPENER = proc{|content|}

    def self.included(base)
      base.extend ClassMethods
    end

    def open_as(type)
      @opened_as ||= {}

      unless @opened_as.member? type
        @opened_as[type] = self.class.opener_for(type)[content]
      end

      if opened_as_type = @opened_as[type]
        yield opened_as_type
      end
    end

    module ClassMethods

      def self.extended(base)
        base.instance_variable_set :@opener, {}
      end

      def inherited(base, copy = {})
        super base
        @opener.each { |type, opener| copy[type] = opener }
        base.instance_variable_set :@opener, copy
      end
      def opener(type, opener = nil)
        @opener[type] = opener || Proc.new
      end
      def opener_for(type)
        @opener.fetch type, DEFAULT_OPENER
      end

    end
  end

end
