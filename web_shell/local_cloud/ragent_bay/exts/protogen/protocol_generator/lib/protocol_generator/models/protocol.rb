require_relative 'protocol_validator'

module ProtocolGenerator

  module Models

    # A protocol is a set of messages and sequences.
    # Protogen needs to handle several protocol versions, hence a version is associated to a protocol.
    # A protocol version is constitued by the version of Protogen that generated the protocol, and
    # the version of the protocol file.
    class Protocol

      attr_accessor :protocol_version, :protogen_version, :name

      def initialize(params = {})
        @messages = params[:messages] || {}
        @sequences = params[:sequences] || {}
        @protogen_version = params[:protogen_version]
        @protocol_version = params[:protocol_version]
        @cookies = params[:cookies] || {}
        @callbacks = {}
        @callbacks[:generic_error_callback] = params[:generic_error_callback]
        @version_string = nil
      end

      # @params [ProtocolGenerator::Models::Message] msg a message to add to hsi protocol
      # @return `true` is the message name was already declared in the protocol, `false` otherwise
      def add_message(msg)
        out = false
        if @messages.has_key?(msg.name)
          out = true
        end
        @messages[msg.name] = msg
        changed
        out
      end

      # Add a sequence ot the protocol. Every message used by the sequence must have been added to the protocol prior to calling this method. This method will check that the given sequence is compatible with the protocol messages.
      # @params [ProtocolGenerator::Models::Sequence] seq a sequence to add to his protocol
      # @return `true` is the sequence name was already declared in the protocol, `false` otherwise
      def add_sequence(seq)
        out = false
        if @sequences.has_key?(seq.name)
          out = true
        end
        seq.shots.each do |shot|
          type = get_message(shot.message_type.name)
          if type.nil?
            raise Error::SequenceError.new("In sequence #{seq.name}, shot #{shot_name}: The message type #{shot.message_type.name} is not defined in the protocol.")
          elsif shot.way != type.way
            raise Error::SequenceError.new("The message #{type.name} has its 'way' set to #{type.way}, incompatible with the shot #{shot.name} way #{shot.way}")
          end
        end
        @sequences[seq.name] = seq
        changed
        out
      end

      # @param cb_name [Symbol]
      # @param cb [String]
      def add_callback(cb_name, cb)
        # todo(faucon_b): check that the callback is valid
        @callbacks[cb_name] = cb
        changed
      end

      # @param [Models::Cookie] cookie
      # @return `true` if a cookie with the same name already exists, false otherwise
      def add_cookie(cookie)
        out = false
        if @cookies.has_key?(cookie.name)
          out = true
        end
        @cookies[cookie.name] = cookie
        changed
        out
      end

      def has_cookies?
        !@cookies.empty?
      end

      def has_message?(msg_name)
        @messages.has_key?(msg_name)
      end

      # @param [String] msg_name name of the message to retrieve
      # @see ProtocolGenerator::Models::Messages#name
      # todo(faucon_b) replace with message(:name, "name")
      def get_message(msg_name)
        @messages[msg_name]
      end

      def get_cookie(cookie_name)
        @cookies[cookie_name]
      end

      # Return messages meeting a given criteria
      # If no argument is give, returns all messages.
      # @example Messages that the device can send to the server
      #     get_messages :sendable_from, :device
      # @example Messages that the server can receive (yes, that is the same thing)
      #     get_messages :receivable_from, :server
      #
      # @return [Array<ProtocolGenerator::Models::Messages>] an array of messages meeting the given criterion
      def messages(*args)
        if args.size == 0
          return @messages.values
        elsif args.size == 2
          case args[0]
          when :sendable_from
            return get_sendable_messages(args[1])
          when :receivable_from
            case args[1]
            when :device
              return get_sendable_messages(:server)
            when :server
              return get_sendable_messages(:device)
            end
          end
        else
          raise ArgumentError.new("Bad request (see get_messages docs)")
        end
      end

      # Return all sequences meeting the given criteria. If no criteria is given, all sequences are returned.
      # @example
      #     sequences(:first_shot, :to_server)
      # @return [Array<ProtocolGenerator::Models::Sequences>] all sequences meeting the given criteria
      def sequences(*args)
        if args.size == 0
          return @sequences.values
        elsif args.size == 2 && args[0] == :first_shot && [:to_device, :to_server].include?(args[1])
          return @sequences.values.select{|seq| seq.shot(:first).way == args[1] }
        else
          raise ArgumentError.new("Unknown criteria: #{args}")
        end
      end

      def cookies
        @cookies.values
      end

      # @example
      #   sequence_by(:id, 3)
      # @return [Models::Sequence] the sequence meeting the given criteria (may be nil)
      def sequence_by(criteria, value)
        case criteria
        when :id
          @sequences.select{|seq_name, seq| seq.id == value}.first
        else
          raise ArgumentError.new("Unknown criteria: #{criteria}")
        end
      end

      # @return [Array<String>] the names of the declared messages
      def msg_names
        @messages.keys
      end

      # @return [Array<ProtocolGenerator::Models::Messages>] an array of messages that can be sent from the @a sender
      def get_sendable_messages(sender)
        case sender
        when :device
          return @messages.select{|msg_name, msg| msg.way == :to_server}.values
        when :server
          return @messages.select{|msg_name, msg| msg.way == :to_device}.values
        else
          raise ArgumentError.new("Unknown sender: #{sender} (expected either :server or :device")
        end
      end

      def get_sequence(seq_name)
        @sequences[seq_name]
      end

      # Compute unique ids for each sequence in the protocol
      # The order of these ids is arbitrary
      def compute_sequences_id
        @sequences.values.each_with_index do |seq, i|
          seq.id = i
        end
        changed
      end

      def compute_messages_id
        @messages.values.each_with_index do |msg, i|
          msg.id = i
        end
        changed
      end

      def compute_cookies_id
        @cookies.values.each_with_index do |cookie, i|
          cookie.id = i
        end
        changed
      end


      # Compute unique ids for each message, each cookie, each sequence and each shot in each sequence.
      def compute_ids
        compute_messages_id
        compute_cookies_id
        compute_sequences_id
        @sequences.values.each do |seq|
          seq.compute_shots_id
        end
        changed
      end

      # Check that the protocol is valid
      # todo(faucon_b): actually implement that
      def validate
        ProtocolValidator.new.validate(self)
      end

      # @param [Symbol] cb
      def has_callback?(cb)
        !@callbacks[cb].nil?
      end

      # @param [Symbol] cb
      def callback(cb)
        @callbacks[cb]
      end

      # A version string is defined as follow: <protogen_version>-<protocol_version>-<hex_string>
      # The hex_string is computed from the protogen and protocol version, and from the defined messages, sequences and cookies.
      # So it should change as soon as a (relevant) modification is done to the protocol file, even if the user
      # forgot to change the protocol version.
      def version_string
        @version_string || compute_version_string
      end


      private

      # Call this method each time the protocol is modified
      # (to indicate the version string needs to be recomputed)
      def changed
        @version_string = nil
      end

      def compute_version_string
        # Messages order declaration does not matter, so we sort the keys
        out_string = "messages"
        @messages.keys.sort.each do |msg_name|
          msg = get_message(msg_name)
          out_string << msg.name
          out_string << msg.way.to_s
          out_string << "fields"
          msg.fields.sort_by{|field| field.name}.each do |field|
            out_string << field.name
            out_string << field.required?.to_s
            out_string << field.array?.to_s
            out_string << field.type.name
          end
        end
        if has_cookies?
          out_string << "cookies"
          @cookies.keys.sort.each do |cookie_name|
            cookie = get_cookie(cookie_name)
            out_string << cookie.name
            out_string << cookie.security_level.to_s
            out_string << cookie.send_with.map{|message| message.name}.join("")
            cookie.fields.sort_by{|field| field.name}.each do |field|
              out_string << field.name
              out_string << field.required?.to_s
            end
          end
        end
        out_string << "sequences"
        @sequences.keys.sort.each do |sequence_name|
          seq = get_sequence(sequence_name)
          out_string << seq.name
          out_string << seq.shot(:first).name
          out_string << "shots"
          seq.shots.sort_by{|shot| shot.name}.each do |shot|
            shot = seq.shot(:name, shot.name)
            out_string << shot.name
            out_string << shot.next_shots.map{ |shot| shot.name }.join("")
            out_string << shot.message_type.name
            out_string << shot.defined_callbacks.map{|cb| cb.to_s}.join("")
            out_string << shot.way.to_s
          end
        end
        out_string << @protocol_version << @protocol_version.to_s
        @version_string = @protogen_version.to_s + "-" + @protocol_version.to_s + "-" + Digest::SHA1.base64digest(out_string)[0..8] # reduce the version string size by cutting the end - this will increase the probability of a collision but will reduce the exchanged message size, which is great.
      end

    end

  end

end