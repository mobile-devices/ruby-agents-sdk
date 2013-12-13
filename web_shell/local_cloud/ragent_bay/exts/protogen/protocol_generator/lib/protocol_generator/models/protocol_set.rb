require_relative 'config'

module ProtocolGenerator

  module Models

    class ProtocolSet

      include Enumerable

      attr_accessor :protocols, :config

      def initialize(params = {})
        @protocols = params[:protocols] || []
        @config = params[:config] || Models::Config.new
      end

      def config=(new_config)
        @config = new_config
      end

      # If no block is given, return the config object. If a block is given, yield to this block in the context of the config object.
      # @example
      #     config do
      #       set :java, :property, "value"
      #       value = get :java, :property
      #     end
      def config(&block)
        if block_given?
          @config.instance_eval(&block)
        else
          @config
        end
      end

      def each(&block)
        protocols.each do |protocol|
          yield protocol
        end
      end

      def <<(protocol)
        @protocols << protocol
      end

    end

  end

end