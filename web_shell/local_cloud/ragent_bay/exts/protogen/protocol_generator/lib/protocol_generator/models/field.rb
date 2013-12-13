module ProtocolGenerator

  module Models

    class Field

      attr_accessor :required, :docstring
      attr_reader :name

      def initialize(params = {})
        self.type = params[:type] # if a string, it is a basic type. If not, it is a Models::Message
        @required = params[:required]
        @docstring = params[:docstring]
        @name = params[:name]
      end

      def required=(is_required)
        @required = is_required
      end

      def required?
        @required
      end

      def type=(new_type)
        if new_type.is_a? String
          @type = Models::BasicType.new({name: new_type})
        elsif new_type.is_a? Models::Type
          @type = new_type
        elsif new_type.nil?
          @type = nil
        else
          raise TypeError.new("A field type can only be a string (for basic types) or a ProtocolGenerator::Models::Type, got #{new_type.class}")
        end
      end

      def type
        @type
      end

      def array?
        false
      end

      def basic_type?
        @type.basic_type?
      end

      def name=(new_name)
        if new_names.match(/^[a-z]/)
          @name = new_name
        else
          raise Error::ProtocolDefinitionError.new("The name of a field must begin with an uppercase letter, got #{new_name}.")
        end
      end

    end

    class ArrayField < Field

      def array?
        true
      end

    end

  end

end