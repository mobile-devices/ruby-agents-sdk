module ProtocolGenerator

  module Models

    class Cookie

      attr_accessor :docstring, :send_with, :validity_period, :id # in seconds
      attr_reader :name

      def initialize(params = {})
        @docstring = params[:docstring]
        if params[:fields]
          params[:fields].each do |field|
            add_field(field)
          end
        else
         @fields = {}
        end
        self.name = params[:name]
        @send_with = params[:send_with] || []
        @validity_period = params[:validity_period]
      end

      # @return `true` is the field name was already defined for this message, false otherwise
      def add_field(field)
        unless field.type.basic_type?
          raise Error::CookieError.new("Cookie field can only be a basic type (got #{field.message_type.name})")
        end
        out = false
        if @fields.has_key?(field.name)
          out = true
        end
        @fields[field.name] = field
        out
      end

      # @return [Array<Models::Fields>] all cookies fields
      def fields
        @fields.values
      end

      def security_level
        @security_level
      end

      def name=(new_name)
        if new_name.match(/^[A-Z]/)
          @name = new_name
        else
          raise Error::ProtocolDefinitionError.new("The name of a cookie must begin with an uppercase letter, got #{new_name}.")
        end
      end

      def security_level=(level)
        if level != :high && level != :low && level != :none
          raise Error::CookieError.new("Cookie security level can only be :high, :low, or :none, got #{level}")
        end
        @security_level = level
      end

    end

  end

end