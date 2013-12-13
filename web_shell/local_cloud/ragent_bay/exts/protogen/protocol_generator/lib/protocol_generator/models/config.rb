module ProtocolGenerator

  module Models

    # Holds configuration values that should be made accessible to all plugins, for a given protocol
    # It is basically a hash for now, but using a separate class will allow for more refined behaviour if needed in the future.
    class Config

      def initialize(args = nil)
        @conf = args || {java: {}, ruby: {}, global: {}}
      end

      # @example
      #    get(:java, :message_class)
      #    get(:ruby, :agent_name)
      def get(type, key)
        @conf[type][key]
      end

      def set(type, key, value)
        @conf[type][key] = value
      end

    end

  end

end