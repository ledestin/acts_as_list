module ActiveRecord::Acts::List::PositionColumnMethodDefiner #:nodoc:
  def self.call(caller_class, position_column)
    define_instance_methods(caller_class, position_column)
    define_class_methods(caller_class, position_column)

    enable_mass_assignment(caller_class, position_column) if user_uses_mass_assignment?(caller_class)
  end

  private

  def self.define_class_methods(caller_class, position_column)
    caller_class.class_eval do
      define_singleton_method :quoted_position_column do
        @_quoted_position_column ||= connection.quote_column_name(position_column)
      end

      define_singleton_method :quoted_position_column_with_table_name do
        @_quoted_position_column_with_table_name ||= "#{quoted_table_name}.#{quoted_position_column}"
      end
    end
  end

  def self.define_instance_methods(caller_class, position_column)
    caller_class.class_eval do
      # Stock Rails #position_changed? can't be used because we consider position changed if there was an assignemnt,
      # regardless of whether the value has changed.
      attr_reader :position_changed

      define_method :position_column do
        position_column
      end

      define_method :"#{position_column}=" do |new_position|
        write_attribute(position_column, new_position)
        @position_changed = true
      end
    end
  end

  def self.enable_mass_assignment(caller_class, position_column)
    caller_class.class_eval do
      attr_accessible position_column.to_sym
    end
  end

  def self.user_uses_mass_assignment?(caller_class)
    caller_class.class_eval do
      defined?(accessible_attributes) and accessible_attributes.present?
    end
  end
end
