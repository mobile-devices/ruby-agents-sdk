require_relative 'type'

module ProtocolGenerator

  module Models

    class Message < Type

      attr_accessor :docstring, :id
      attr_reader :name

      def initialize(params = {})
        self.way = params[:way] || :none
        @docstring = params[:docstring]
        if params[:fields]
          params[:fields].each do |field|
            add_field(field)
          end
        else
         @fields = {}
        end
        self.name = params[:name]
      end

      # @return `true` is the field name was already defined for this message, false otherwise
      def add_field(field)
        # todo(faucon_b): check that field is "complete" (maybe add a method in field to check that)
        out = false
        if @fields.has_key?(field.name)
          out = true
        end
        @fields[field.name] = field
        out
      end

      # @return [Array<ProtocolGenerator::Models::Field] all the fields of this message (this excludes configuration fields)
      def fields
        @fields.values
      end

      def get_field(field_name)
        @fields[field_name]
      end

      def way=(new_way)
        if new_way != :to_server && new_way != :to_device && new_way != :none
          raise ArgumentError.new("A message way can only be :to_server, :to_device, or :none, got #{new_way}")
        end
        @way = new_way
      end

      def way
        @way
      end

      def sendable?
        @way != :none
      end

      def basic_type?
        false
      end

      def name=(new_name)
        if new_name.match(/^[A-Z]/)
          @name = new_name
        else
          raise Error::ProtocolDefinitionError.new("The name of a message must begin with an uppercase letter, got #{new_name}.")
        end
      end

    end

  end

end