module Spira
  module Resource
    module Validations

      def errors
        @errors ||= []
      end

      def assert(boolean, message)
        errors.push(message) unless boolean
      end

      def assert_set(name)
        assert(!(self.send(name).nil?), "#{name.to_s} cannot be nil")
      end

      def assert_numeric(name)
        assert(self.send(name).is_a?(Numeric), "#{name.to_s} must be numeric (was #{self.send(name)})")
      end

    end
  end
end
