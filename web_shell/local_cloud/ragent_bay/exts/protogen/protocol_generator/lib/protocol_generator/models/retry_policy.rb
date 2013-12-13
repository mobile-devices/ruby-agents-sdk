module ProtocolGenerator

  module Models

    class RetryPolicy

      attr_accessor :attempts # delay in seconds
      attr_reader :delay

      def initialize(params = {})
        @attempts = params[:attempts] || -1
        @delay = params[:delay]
      end

      def infinite_attempts?
        @attempts < 0
      end

      def delay=(value)
        if value > 0
          @delay = value
        else
          raise ArgumentError.new("Delay must be a positive integer.");
        end
      end

    end

  end

end