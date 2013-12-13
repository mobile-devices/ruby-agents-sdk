module ProtocolGenerator

  module Models

    class Type

      def initialize(params)
      end

      # @return the class *object* (Models::Message or Models::BasicType)
      def self.from_name(name)
        if BASIC_TYPES.include?(name)
          return BasicType
        else
          return Message
        end
      end

      def basic_type?
        raise 'abstract method called'
      end

    end

    class BasicType < Type

      attr_reader :name

      # @param [String] name the name of a basic type
      # @return [BasicType] the corresponding, frozen, basic type object
      def self.get_basic_type(name)
        unless BASIC_TYPES.include?(name) # defined in schema.rb
          raise ArgumentError.new("Invalid basic type: #{name}")
        end
        @@basic_type ||= {}
        @@basic_type[name] ||= BasicType.new({name: name}).freeze
      end

      def initialize(params)
        self.name = params[:name]
      end

      def name=(new_name)
        if new_name.nil?
          raise ArgumentError.new("Invalid basic type: nil is not an acceptable type")
        end
        unless BASIC_TYPES.include?(new_name) # defined in schema.rb
          raise ArgumentError.new("Invalid basic type: #{new_name}")
        end
        @name = new_name
      end

      def basic_type?
        true
      end

    end

  end

end