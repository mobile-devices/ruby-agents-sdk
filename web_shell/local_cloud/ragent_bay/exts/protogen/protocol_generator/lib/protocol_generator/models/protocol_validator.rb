module ProtocolGenerator

  # Validate a `ProtocolGenerator::Models::Protocol` against several rules.
  # Should be used only for validation that can be conducted only once the protocol is built,
  # models should raise an exception as soon as they detect they are in a incoherent state.
  # If this class is to grow, consider delegating validation to the models instead.
  class ProtocolValidator

    # Define a method to register validators
    def self.validators(*args)
      @@validators ||= []
      args.each do |validator|
        @@validators << validator
      end
    end

    # Register validators
    # A validator is a method that takes a protocol as parameter, and returns an array of errors.
    # If the returned array is empty, this means that no error occured.
    validators :id_uniqueness, :field_presence, :callback_name_uniqueness, :callback_way_compatibility

    ############################
    # Validators
    def id_uniqueness(protocol)
      out = []
      duplicates = protocol.sequences.group_by{|seq| seq.id}.select{|k, count| count.size > 1}
      if duplicates.size > 0
        out << "Found duplicate sequences id"
      end
      protocol.sequences.each do |seq|
      duplicates = seq.shots.group_by{|shot| shot.id}.select{|k, count| count.size > 1}
        if duplicates.size > 0
          out << "Found duplicate shots id in sequence #{seq.name}"
        end
      end
      duplicates = protocol.messages.group_by{|msg| msg.id}.select{|k, count| count.size > 1}
      if duplicates.size > 0
          out << "Found duplicate messages id"
      end
      out
    end

    def field_presence(protocol)
      out = []
      protocol.messages.each do |msg|
        if msg.fields.size == 0
          out << "Message #{msg.name} has no fields"
        end
      end
      protocol.cookies.each do |cookie|
        if cookie.fields.size == 0
          out << "Cookie #{cookie.name} has no fields"
        end
      end
      out
    end

    def callback_name_uniqueness(protocol)
      out = []
      protocol.sequences.each do |seq|
        seq_callbacks = []
        seq.shots.each do |shot|
          seq_callbacks.concat(shot.callbacks)
        end
        if seq_callbacks.uniq.size != seq_callbacks.size
          out << "Duplicate callback name found in sequence #{seq.name}"
        end
      end
      out
    end

    def callback_way_compatibility(protocol)
      out = []
      protocol.sequences.each do |seq|
        seq.shots.each do |shot|
          out << "Invalid callbacks in shot #{shot.name} sequence #{seq.name}" unless shot.validate_callbacks
        end
      end
      out
    end

    ###################################
    # Call this to validate a protocol
    # @return [Boolean, Hash<String, Array<String>>] a list of encountered errors while validating the protocol
    #    The returned Boolean indicates if the protocol was validated.
    def validate(protocol)
      err = {}
      validated = true
      @@validators.each do |validator|
        errors = self.send(validator, protocol)
        if errors.size > 0
          err[validator] = errors
          validated = false
        end
      end
      [validated, err]
    end

  end

end