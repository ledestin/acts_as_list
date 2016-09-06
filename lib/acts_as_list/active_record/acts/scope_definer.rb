module ActiveRecord
  module Acts #:nodoc:
    class ScopeDefiner #:nodoc:
      include ActiveSupport::Inflector

      def self.call(caller_class, scope)
        new(caller_class, scope).call
      end

      def initialize(caller_class, scope)
        @caller_class, @scope = caller_class, scope
      end

      def call
        scope = @scope

        scope = idfy(scope) if scope.is_a?(Symbol)

        @caller_class.class_eval do
          define_method :scope_name do
            scope
          end

          if scope.is_a?(Symbol)
            define_method :scope_condition do
              { scope => send(scope) }
            end

            define_method :scope_changed? do
              changed.include?(scope_name.to_s)
            end
          elsif scope.is_a?(Array)
            define_method :scope_condition do
              scope.inject({}) do |hash, column|
                hash.merge!({ column.to_sym => read_attribute(column.to_sym) })
              end
            end

            define_method :scope_changed? do
              (scope_condition.keys & changed.map(&:to_sym)).any?
            end
          else
            define_method :scope_condition do
              eval "%{#{scope}}"
            end

            define_method :scope_changed? do
              false
            end
          end
        end
      end

      def idfy(name)
        return name if name.to_s =~ /_id$/

        foreign_key(name).to_sym
      end
    end
  end
end
