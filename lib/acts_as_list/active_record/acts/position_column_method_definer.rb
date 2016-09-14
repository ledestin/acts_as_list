module ActiveRecord::Acts::List::PositionColumnMethodDefiner #:nodoc:
  SELF = self

  def self.call(caller_class, position_column)
    caller_class.class_eval do
      attr_reader :position_changed

      define_method :position_column do
        position_column
      end

      define_method :"#{position_column}=" do |new_position|
        write_attribute(position_column, new_position)
        @position_changed = true
      end

      SELF.enable_mass_assignment(position_changed) if SELF.user_uses_rails_3_mass_assignment?

      define_singleton_method :quoted_position_column do
        @_quoted_position_column ||= connection.quote_column_name(position_column)
      end

      define_singleton_method :quoted_position_column_with_table_name do
        @_quoted_position_column_with_table_name ||= "#{caller_class.quoted_table_name}.#{quoted_position_column}"
      end
    end
  end

  private

  def self.enable_mass_assignment(position_column)
    attr_accessible position_column.to_sym
  end

  def self.user_uses_rails_3_mass_assignment?
    defined?(accessible_attributes) and !accessible_attributes.blank?
  end
end
