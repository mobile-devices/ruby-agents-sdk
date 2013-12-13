module ProtocolGenerator

  module Models

    class Shot

      attr_accessor :message_type, :name, :id, :retry_policy
      attr_reader :next_shots

      def initialize(params = {})
        self.way = params[:way]
        @name = params[:name]
        @message_type = params[:message_type] # Models::Message
        @callbacks = {}
        AVAILABLE_CALLBACKS.each do |cb|
          add_callback(cb, params[cb]) if params[cb] # string
        end
        @next_shots = params[:next_shots] || []
        @id = params[:id]

        @timeouts = {}
        if (params[:send_timeout] || params[:receive_timeout]) && self.way == :toDevice
          raise Error::ProtogenError.new("Protogen does not handle server-side timeouts.")
        end
        @timeouts[:send] = params[:send_timeout] if params[:send_timeout]
        @timeouts[:receive] = params[:receive_timeout] if params[:receive_timeout]
      end

      # @return `true` if it this shot does not have any "next shots" defined
      def last?
        @next_shots.size == 0
      end

      def way=(new_way)
        if new_way != :to_server && new_way != :to_device
          raise ArgumentError.new("A shot way can only be :to_server or :to_device, got #{way}")
        end
        unless @message_type.nil?
          if @message_type.way != new_way
            raise ArgumentError.new("Shot way set to #{new_way} while its message type has 'way' set to #{@message_type.way}")
          end
        end
        @way = new_way
      end

      def way
        @way
      end

      def next_shots=(next_shots)
        unless next_shots.is_a? Array # to prevent next_shots from being nil
          raise ArgumentError.new("Next shots can't be nil (but can be an empty array)")
        end
        @next_shots = next_shots
      end

      # @param [Symbol] cb a specific callback (as :received_callback)
      def has_callback?(cb)
        @callbacks.has_key?(cb)
      end

      # @param [Symbol] cb callback type
      # @params [String] cb_name name of the callback
      def add_callback(cb, cb_name)
        if AVAILABLE_CALLBACKS.include?(cb)
          if(validate_callback_name(cb))
            @callbacks[cb] = cb_name
          else
            raise Error::SequenceError.new("Invalid callback name: #{cb_name}")
          end
        else
          raise Error::ProtogenError.new("Invalid callback: #{cb}, expected one of #{AVAILABLE_CALLBACKS.inspect}")
        end
      end

      # @param [Symbol] cb a callback
      # @return [String] the callback name (nil if no callback name was defined for this callback
      # @raise [Error::ProtogenError] if the @a cb parameter is not a callback that Protogen accepts.
      def callback(cb)
        if AVAILABLE_CALLBACKS.include?(cb)
          return @callbacks[cb]
        else
          raise Error::ProtogenError.new("Invalid callback: #{cb}, expected one of #{AVAILABLE_CALLBACKS.inspect}")
        end
      end

      # @return [Array<Symbol>] the list of the callbacks the user explicitely defined for this shot
      def defined_callbacks
        @callbacks.keys
      end

      def callbacks
        @callbacks.values
      end

      # @param [Symbol] event :send or :receive (if applicatble)
      # @return [Fixnum] the timeout for the given event (the default value is used if it was not explicitely defined before)
      # @raise [Error::ProtogenError] when trying to access an invalid event or when asking for the :receive event when no server reply is expected
      def timeout(event)
        unless [:receive, :send].include?(event)
          raise Error::ProtogenError.new("Invalid timeout event: #{event}")
        end
        if event == :receive && self.last?
          raise Error::ProtogenError.new("No response timeout is available for shots that do not expect a reply.")
        end
        if @timeouts.has_key?(event)
          return @timeouts[event]
        else
          return DEFAULT_TIMEOUT[event] #defined in schema.rb
        end
      end

      # Check that the :recievd_callbacks is defined, and if the way is set to :toDevice, that no other
      # callback is defined.
      # @return [Boolean]
      def validate_callbacks
        if @way == :to_device
          return @callbacks.has_key?(:received_callback) && @callbacks.size == 1
        else
          return @callbacks.has_key?(:received_callback)
        end
      end

      def has_retry_policy?
        !@retry_policy.nil?
      end

      private

      def validate_callback_name(name)
        name.match(/^[a-z]/)
      end

    end

  end

end