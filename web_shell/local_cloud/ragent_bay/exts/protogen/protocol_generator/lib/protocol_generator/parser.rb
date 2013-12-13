require_relative 'models/field'
require_relative 'models/message'
require_relative 'models/sequence'
require_relative 'models/shot'
require_relative 'models/sequence'
require_relative 'models/protocol'
require_relative 'models/protocol_set'
require_relative 'models/config'
require_relative 'models/cookie'
require_relative 'models/retry_policy'
require_relative 'schema.rb'

module ProtocolGenerator

  class Parser

    # @param [Hash<String, Object>] params a hash with the following keys:
    #     * temp_output_directory: a temporary output directory to be used by Protogen.
    #     * default_config_path: path to the default protogen configuration file
    #     * config_path: path to the user configuration file
    #     * protocol_path: an array of protocol configuration file
    def self.run(params)
      puts "Reading configuration..."
      hash_config = read_config(params['default_config_path'], params['config_path'])

      protocol_set = Models::ProtocolSet.new
      protocol_set.config do
        set :java, :package_name, hash_config['java_package']
        set :java, :output_directory, hash_config['device_output_directory']
        set :ruby, :agent_name, hash_config['agent_name']
        set :ruby, :user_callbacks_directory, hash_config['user_callbacks']
        set :ruby, :max_message_size, hash_config['message_size_limit']
        set :ruby, :message_part_size, hash_config['message_part_size']
        set :java, :output_path, hash_config['device_output_directory']
        set :ruby, :output_path, hash_config['server_output_directory']
        set :java, :temp_output_path, File.join(params['temp_output_directory'], "device")
        set :ruby, :temp_output_path, File.join(params['temp_output_directory'], "server")
        set :java, :mdi_jar_path, hash_config['mdi_framework_jar']
        set :java, :keep_jar, hash_config['keep_java_jar']
        set :java, :keep_source, hash_config['keep_java_source']
        set :global, :plugins, hash_config['plugins']
        set :global, :pg_version, hash_config['pg_version']
        set :java, :max_message_size, hash_config['device_message_size_limit']
        set :java, :message_part_expiration_duration, hash_config['device_message_part_expiration_duration'] # in seconds
        set :ruby, :message_part_expiration_duration, hash_config['server_message_part_expiration_duration']
        set :ruby, :generate_documentation, hash_config['generate_ruby_documentation']
      end

      params['protocol_path'].each do |protocol_path|
        protocol_set << declare_protocol(protocol_path)
      end

      protocol_set.freeze
    end

    def self.declare_protocol(protocol_path)

      protocol = Models::Protocol.new

      puts "\n\nReading the protocol definition file at #{protocol_path}...\n"
      input = read_protocol_file(protocol_path)

      protocol.protogen_version = input["protogen_version"]
      protocol.protocol_version = input["protocol_version"]
      protocol.name = input["name"]
      protocol.add_callback(:generic_error_callback, input["generic_error_callback"]) if input['generic_error_callback']

      # Messages
      puts "Building messages..."
      declared_types = []
      input['messages'].each do |msg_name, msg_def|
        declare_message(msg_name, protocol, input['messages'])
      end

      # Cookies
      puts "Building cookies..."
      use_cookies = input.has_key?('cookies') && !input['cookies'].empty?
      if use_cookies
        input['cookies'].each do |cookie_name, cookie_def|
          puts "Adding cookie #{cookie_name}..."
          if cookie_def['_secure'].nil?
            secure = nil
          else
            secure = cookie_def['_secure'].to_sym
          end
          cookie = Models::Cookie.new({docstring: cookie_def['docstring'], name: cookie_name, validity_period: cookie_def['_validity_time'], security_level: secure})
          send_with = cookie_def['_send_with'].each do |msg_name|
            msg = protocol.get_message(msg_name)
            if msg == nil
              raise Error::CookieError.new("In cookie #{cookie_name}, '_send_with' message type set to #{msg_name} which is an unknown message type.")
            end
            cookie.send_with << msg
          end
          fields = cookie_def.select { |key, value| key.match(/^[a-z]/) }
          if fields.size > 10
            raise Error::CookieError.new("A cookie can not have more than 10 fields.")
          end
          fields.each do |field_name, field_def|
            field = Models::Field.new(type: field_def['type'], required: field_def['modifier'] == 'required', name: field_name, docstring: field_def['docstring'])
            cookie.add_field(field)
          end
          protocol.add_cookie(cookie)
        end
      end # if use_cookies

      # Sequences
      puts "Building sequences..."
      input['sequences'].each do |seq_name, seq_def|
        puts "Declaring sequence #{seq_name}"
        seq = Models::Sequence.new({name: seq_name, aborted_callback: seq_def['aborted_callback'], docstring: seq_def["docstring"]})
        declare_shot(seq_def['first_shot'], seq, seq_def['shots'], protocol)
        seq.first_shot = seq.shot(:name, seq_def['first_shot'])
        protocol.add_sequence(seq)
      end

      protocol.compute_ids

      puts "Final protocol validation..."
      validated, errors = protocol.validate
      unless validated
        puts "Validation errors"
        puts errors.inspect
        raise Error::ValidationError.new("Final protocol was not validated")
      end

      puts "Protocol version: #{protocol.version_string}"

      protocol.freeze
    end # self.declare_protocol

    # Add a new message to the given @a protocol. Will also recursively add to the protocol every message used in a field of the given message.
    # @param [String] msg_name name of the message to add
    # @param [Protogen::Models::Protocol] protocol the protocol to which this message will be added (will be modified)
    # @param [Hash<String, Object>] messages definition of all messages
    # @return the updated protocol
    # @raise Protogen::Error::ProtocolDefinitionError
    def self.declare_message(msg_name, protocol, messages)
      if protocol.has_message?(msg_name) || BASIC_TYPES.include?(msg_name)
        return protocol
      end
      puts "Declaring #{msg_name}..."
      unless messages.has_key?(msg_name)
        raise Error::ProtocolDefinitionError.new("Unknown message type: '#{msg_name}' (if you actually defined this type, be sure that you have no circular dependency ie A.b is of type B and B.a if of type A).")
      end
      msg_def = messages[msg_name]
      msg = Models::Message.new(docstring: msg_def['_docstring'], name: msg_name)
      msg.way = way_string_to_symbol(msg_def['_way'])
      fields = msg_def.select { |key, value| key.match(/^[a-z]/) }
      fields.each do |field_name, field_def|
        type = field_def['type']
        # Make sure the required type is declared
        unless protocol.has_message?(type) || BASIC_TYPES.include?(type)
          # To avoid infinite recursion, we remove the current message from the list of possible messages.
          # Doing so will raise an error if there is a cycle in the message type dependency graph.
          messages_copy = messages.clone
          messages_copy.delete(msg_name)
          declare_message(type, protocol, messages_copy)
        end
        params = {required: field_def['modifier'] == 'required', docstring: field_def["docstring"], name: field_name}
        if BASIC_TYPES.include?(type)
          params[:type] = type
        else
          params[:type] = protocol.get_message(type) # we know that the message has been declared earlier
        end
        if msg_def['array'] == true
          field = Models::ArrayField.new(params)
        else
          field = Models::Field.new(params)
        end
        msg.add_field(field)
      end
      protocol.add_message(msg)
      protocol
    end

    # Add a new shot to the given @a protocol.
    # Will also recursively add to the sequence every shot defined as a "next_shot", and will take care of not going into infinite recursion if ShotA has ShotB as next shot and ShotB has ShotA as next shot (for instance).
    # A well-formed sequence declaration should need to call this method with only the first shot and all the shots will be declared.
    # @param [String] shot_name name of the shot to add (should be the first shot in the sequence)
    # @param [ProtocolGenerator::Models::Sequence] sequence the sequence to which this shot will be added (will be modified).
    #     This method assumes the attribute "name" of the sequence is already set.
    # @param [Hash<String, Object>] shots definition of all shots
    # @param [ProtocolGenerator::Models::Protocol] the protocol used (messages used in the sequence must have been declared in this protocol)
    # @return the updated sequence (to make sure all shots have been correctly declared, consider comparing the number of shots in this sequence to the expected number of shots)
    # @raise Protogen::Error::SequenceError
    def self.declare_shot(shot_name, sequence, shots, protocol)
      unless shots.has_key?(shot_name)
        # The given shot is not in the list. This is not an error if the shot has already been declared,
        # because we delete a declared shot from the "shots" parameter before the recursive call.
        if sequence.has_shot?(shot_name)
          return sequence
        else
          raise ArgumentError.new("The shot #{shot_name} is not declared in sequence #{sequence.name}")
        end
      end
      puts "Declaring shot #{shot_name}..."
      if shots[shot_name].has_key?('next_shots')
        shots_copy = shots.clone
        next_shots = shots_copy[shot_name]['next_shots']
        shots_copy.delete(shot_name) # mark the shot as declared ("visited" in a graph) by deleting it
        next_shots.each_with_index do |next_shot, i|
          declare_shot(next_shot, sequence, shots_copy, protocol)
        end
      end
      # At this point we know that all of our "next_shots" have been declared.
      shot_def = shots[shot_name]
      message_type = protocol.get_message(shot_def['message_type'])
      if message_type.nil?
        raise Error::SequenceError.new("In sequence #{sequence.name}, shot #{shot_name}: message type #{shot_def['message_type']} is not defined.")
      end
      params = {name: shot_name, way: way_string_to_symbol(shot_def['way']), message_type: message_type}
      next_shots = []
      if shot_def.has_key?('next_shots')
        shot_def['next_shots'].each do |next_shot|
          next_shots << sequence.shot(:name, next_shot)
        end
      end
      if shot_def.has_key?('timeouts')
        if shot_def['way'] == "toDevice"
          raise Error::SequenceError.new("Protogen does not handle server-side timeouts (invalid attribute 'timeouts' in shot #{shot_name} sequence #{sequence.name})")
        end
        if shot_def['timeouts'].has_key?('send')
          params[:send_timeout] =  shot_def['timeouts']['send']
        end
        if shot_def['timeouts'].has_key?('receive')
          unless shot_def.has_key?('next_shots')
            raise Error::SequenceError.new("Can not define a response timeout for a shot that does not expect a reply (invalid attribute 'receive' in timeouts defined for the shot #{shot_name} sequence #{sequence.name})")
            end
          params[:receive_timeout] = shot_def['timeouts']['receive']
        end
      end
      params[:next_shots] = next_shots
      shot = Models::Shot.new(params)
      AVAILABLE_CALLBACKS.each do |cb|
        shot.add_callback(cb, shot_def[cb.to_s]) if shot_def.has_key?(cb.to_s)
      end

      # Retry policy
      if shot_def.has_key?("retry_policy")
        retry_policy = Models::RetryPolicy.new(:delay => shot_def["retry_policy"]["delay"], :attempts => shot_def["retry_policy"]["attempts"])
        shot.retry_policy = retry_policy
      end

      sequence.add_shot(shot)
    end

    def self.way_string_to_symbol(way)
      case way
      when "toDevice"
        return :to_device
      when "toServer"
        return :to_server
      when "none"
        return :none
      else
        raise Error::ProtocolDefinitionError.new("Unknown message way: #{way.inspect}")
      end
    end

    # Read, validate and merge the default conf and the config conf.
    # @return [Hash<String, Object] the result of merging the default conf and the config conf.
    def self.read_config(default_config_path, config_path)
      # Default config
      unless File.exist?(default_config_path)
        raise Error::ConfigurationFileError.new("Can not find the default configuration file at #{default_config_path}")
      end
      begin
        hash_config = JSON.parse(File.open(default_config_path).read)['default']
      rescue JSON::ParserError => e
        raise Error::ConfigurationFileError.new("Error when JSON-parsing the default configuration file at #{default_config_path}: #{e.message}")
      end

      # User config
      unless File.exist?(config_path)
        raise Error::ConfigurationFileError.new("Can not find configuration file at #{config_path}")
      end

      begin
         hash_config.merge!(JSON.parse(File.open(config_path).read))
      rescue JSON::ParserError => e
        raise Error::ConfigurationFileError.new("Error when JSON-parsing the configuration file at #{config_path}: #{e.message}")
      end

      # Configuration validation
      unless hash_config.has_key?('server_output_directory') || hash_config.has_key?('device_output_directory')
        raise Error::ConfigurationFileError.new("The configuration file must specify either the key 'server_output_directory' or 'device_output_directory'.")
      end
      if hash_config['server_output_directory']
        validation_errors = JSON::Validator.fully_validate(Schema::SERVER_CONF, hash_config, :validate_schema => true)
        if validation_errors.size > 0
          raise Error::ConfigurationFileError.new("The configuration file does not follow the correct schema: Errors: #{validation_errors.inspect}.")
        end
      end
      if hash_config['device_output_directory']
        validation_errors = JSON::Validator.fully_validate(Schema::DEVICE_CONF, hash_config, :validate_schema => true)
        if validation_errors.size > 0
          raise Error::ConfigurationFileError.new("The configuration file does not follow the correct schema. Errors: #{validation_errors.inspect}.")
        end
      end

      use_protobuf, use_msgpack = false,false
      hash_config['plugins'].each do |plugin_name|
        if /protobuf/.match(plugin_name)
          puts "Will use protobuf because of plugin #{plugin_name}"
          use_protobuf = true
        end
        if /msgpack/.match(plugin_name)
          puts "Will use protobuf because of plugin #{plugin_name}"
          use_msgpack = true
        end
      end
      if use_protobuf && use_msgpack
        Error::PluginError.new('Conflict: two plugins found using msgpack and protobuf. You can use only one or the other.')
      elsif use_protobuf
        validation_errors = JSON::Validator.fully_validate(Schema::PROTOBUF_CONF, configuration, :validate_schema => true)
        if validation_errors.size > 0
          raise Error::ConfigurationFileError.new("The configuration file do not follow the correct Protobuf schema: #{PROTOBUF_CONF.inspect}")
        end
      elsif use_msgpack
        validation_errors = JSON::Validator.fully_validate(Schema::MSGPACK_CONF, configuration, :validate_schema => true)
        if validation_errors.size > 0
          raise Error::ConfigurationFileError.new("The configuration file do not follow the correct msgpack schema: #{PROTOBUF_CONF.inspect}. Errors: #{validation_errors.inspect}.")
        end
      end

      hash_config
    end

    # Read, parse and validate a protocol_file.
    # @return [Hash] the result of JSON-parsing the protocol file
    def self.read_protocol_file(protocol_file_path)
       unless File.exist?(protocol_file_path)
        raise Error::ProtocolFileNotFound.new("Can not find protocol definition file at #{protocol_file_path}")
      end
      if File.zero?(protocol_file_path)
        raise Error::ProtocolFileEmpty.new("Found empty protocol definition file at #{protocol_file_path}")
      end

      begin
        input = JSON.parse(File.open(protocol_file_path).read)
      rescue JSON::ParserError => e
        raise Error::ProtocolFileParserError.new("Error when JSON-parsing the protocol definition file at #{protocol_file_path}: #{e.message}")
      end

      # General validation
      validation_errors = JSON::Validator.fully_validate(Schema::GENERAL, input, :validate_schema => true)
      if validation_errors.size > 0
        raise Error::ProtocolDefinitionError.new("General schema validation failed, check your input file. Errors: #{validation_errors.inspect}.")
      end

      input
    end

  end
end
