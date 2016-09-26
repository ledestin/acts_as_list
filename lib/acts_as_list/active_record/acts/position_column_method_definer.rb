module ActiveRecord::Acts::List::PositionColumnMethodDefiner #:nodoc:
  def self.call(caller_class, position_column)
    define_class_methods(caller_class, position_column)
    define_instance_methods(caller_class, position_column)

    caller_class.class_eval do
      # only add to attr_accessible
      # if the class has some mass_assignment_protection
      if defined?(accessible_attributes) and !accessible_attributes.blank?
        attr_accessible :"#{position_column}"
      end
    end
  end

  private

  def self.define_class_methods(caller_class, position_column)
    caller_class.class_eval do
      define_singleton_method :quoted_position_column do
        @_quoted_position_column ||= connection.quote_column_name(position_column)
      end

      define_singleton_method :quoted_position_column_with_table_name do
        @_quoted_position_column_with_table_name ||= "#{caller_class.quoted_table_name}.#{quoted_position_column}"
      end

      define_singleton_method :decrement_all do
        update_all_with_touch "#{quoted_position_column} = (#{quoted_position_column_with_table_name} - 1)"
      end

      define_singleton_method :increment_all do
        update_all_with_touch "#{quoted_position_column} = (#{quoted_position_column_with_table_name} + 1)"
      end

      define_singleton_method :update_all_with_touch do |updates|
        record = new
        attrs = record.send(:timestamp_attributes_for_update_in_model)
        now = record.send(:current_time_from_proper_timezone)

        query = attrs.map { |attr| "#{connection.quote_column_name(attr)} = :now" }
        query.push updates
        query = query.join(", ")

        update_all([query, now: now])
      end
    end
  end

  def self.define_instance_methods(caller_class, position_column)
    caller_class.class_eval do
      attr_reader :position_changed

      define_method :position_column do
        position_column
      end

      define_method :"#{position_column}=" do |position|
        write_attribute(position_column, position)
        @position_changed = true
      end
    end
  end
end
