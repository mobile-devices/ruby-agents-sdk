# Defines all errors that can happen when generating a protocol
module ProtocolGenerator

  module Error

    ERROR_CODE = {
      protogen_error: 1,
      protocol_file_error: 3, # 2 is bash reserved code for "misuse of shell builtin"
      protocol_file_not_found: 4,
      protocol_file_empty: 5,
      protocol_parser_error: 6,
      protocol_definition_error: 7,
      configuration_error: 8,
      plugin_error: 9,
      sequence_error: 10,
      cookie_error: 11
    }.freeze

    # Generic Protogen error, all other Protogen errors must subclass this
    class ProtogenError < StandardError
      attr_accessor :exit_code

      def initialize(*args)
        super(*args)
        @exit_code = ERROR_CODE[:protogen_error]
      end
    end

    # Generic error when reading/parsing the protocol File and generating the protocol, probably the most common error
    class GenerationError < ProtogenError
    end

    class ProtocolFileError < GenerationError
      def initialize(*args)
        super(*args)
        @exit_code = ERROR_CODE[:protocol_file_error]
      end
    end

    class ProtocolFileNotFound < ProtocolFileError
      def initialize(*args)
        super(*args)
        @exit_code = ERROR_CODE[:protocol_file_not_found]
      end
    end

    class ProtocolFileEmpty < ProtocolFileError
      def initialize(*args)
        super(*args)
        @exit_code = ERROR_CODE[:protocol_file_empty]
      end
    end

    class ProtocolFileParserError < ProtocolFileError
      def initialize(*args)
        super(*args)
        @exit_code = ERROR_CODE[:protocol_parser_error]
      end
    end

    class ProtocolDefinitionError < ProtocolFileError
      def initialize(*args)
        super(*args)
        @exit_code = ERROR_CODE[:protocol_definition_error]
      end
    end

    class ConfigurationFileError < GenerationError
      def initialize(*args)
        super(*args)
        @exit_code = ERROR_CODE[:configuration_error]
      end
    end

    class PluginError < GenerationError
      def initialize(*args)
        super(*args)
        @exit_code = ERROR_CODE[:plugin_error]
      end
    end

    class SequenceError < ProtocolDefinitionError
      def initialize(*args)
        super(*args)
        @exit_code = ERROR_CODE[:sequence_error]
      end
    end

    class CookieError < ProtocolDefinitionError
      def initialize(*args)
        super(*args)
        @exit_code = ERROR_CODE[:cookie_error]
      end
    end

    class ValidationError < ProtogenError
    end

  end

end