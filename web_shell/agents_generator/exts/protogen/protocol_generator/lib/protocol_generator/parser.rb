module ProtocolGenerator

  BASIC_TYPES = ['int', 'nil', 'bool', 'float', 'bytes', 'string'].freeze
  MSGPACK2JAVA = {
    'int' => 'int',
    'nil' => 'null',
    'bool' => 'boolean',
    'float' => 'float',
    'bytes' => 'byte[]',
    'string' => 'String',
    'msgpack' => 'Value'
  }.freeze

  MSGPACK2RUBY = {
    'int' => 'Fixnum',
    'nil' => 'NilClass',
    'bool' => 'bool', # No bool in ruby... TODO, find a workaroud
    'float' => 'Float',
    'bytes' => 'bytes',
    'string' => 'String',
    'msgpack' => 'Object'

  }.freeze

  SERVER_CONF_SCHEMA = {
    "type" => "object",
    'required' => true,
    "properties" => {
      "plugins" => {'type' => 'array', 'required' => true},
      "agent_name" => {'type' => 'string', 'required' => true},
      "message_size_limit" => {'type' => 'int', 'required' => false},
      "message_part_size" => {'type' => 'int', 'required' => false}
    }
  }.freeze

  DEVICE_CONF_SCHEMA = {
    "type" => "object",
    'required' => true,
    "properties" => {
      "plugins" => {'type' => 'array', 'required' => true},
      "java_package" => {'type' => 'string', 'required' => true},
      "mdi_framework_jar" => {'type' => 'string', 'required' => false},
      "keep_java_source" => {'type' => 'bool', 'required' => false},
      "keep_java_jar" => {'type' => 'bool', 'required' => false},
      "agent_name" => {'type' => 'string', 'required' => true},
      "message_size_limit" => {'type' => 'int', 'required' => false},
      "message_part_size" => {'type' => 'int', 'required' => false}
    }
  }.freeze

  MSGPACK_CONF_SCHEMA = {}.freeze

  PROTOBUF_CONF_SCHEMA = {
    "type" => "object",
    'required' => true,
    "properties" => {
      "proto_file_name" => {'type' => 'string', 'required' => true},
      "protobuf_jar" => {'type' => 'string', 'required' => true},
      "package_name" => {'type' => 'string', 'required' => true}
    }
  }.freeze

  FIELD_SCHEMA = {
    'type' => 'object',
    'properties' => {
      'type' => {'type'=>'string', 'required' => true},
      'modifier' => {'type'=>'string', 'enum' => ['required', 'optional'], 'required' => true},
      'array' => {'type'=>'bool', 'required' => false},
      'docstring' => {'type'=>'string', 'required' => false}
    }
  }.freeze

  MESSAGES_SCHEMA = {
    'type' => 'object',
    'required' => true,
    'properties' => {},
    "patternProperties" => {
      "^[A-Z]" => {
        'type' => 'object',
        'properties' => {
          '_description' => {'type' => 'string', 'required' => false},
          '_way' => {'type' => 'string', 'enum' => ['toServer', 'toDevice', 'both', 'none'], 'required' => true},
          '_server_callback' => {'type' => 'string', 'required' => false},
          '_device_callback' => { 'type' => 'string', 'required' => false},
          '_timeout_calls' => {'type' => 'Array', 'required' => false}, # ["send", "ack"]
          '_timeouts' => {
            'type' => 'object',
            'required' => false,
            'properties' => {
              'send' => {'type' => 'int', 'required' => false},
            }
          }
        },
        "patternProperties" => {
          "^[a-z]" => FIELD_SCHEMA
        }
      }
    }
  }.freeze

  COOKIES_SCHEMA = {
    'type' => 'object',
    'required' => true,
    'properties' => {},
    "patternProperties" => {
      "^[A-Z]" => {
        'type' => 'object',
        'properties' => {
          "_send_with" => { 'type' => 'Array' },
          "_secure" => { 'type' => 'string', 'enum' => ['high', 'low', 'none']},
          "_validity_time" => {'type' => 'int', 'required' => false}
          },
        "patternProperties" => {
          "^[a-z]" => FIELD_SCHEMA
        }
      }
    }
  }.freeze

  SHOTS_SCHEMA = {
    "type" => "object",
    "required" => true,
    "patternProperties" => {
      "^[A-Z]" => {
        "type" => "object",
        "properties" => {
          "way" => {"type" => "string", "required" => true, "enum" => ['toDevice', 'toServer']},
          "message_type" => {"type" => "string", "required" => true},
          "next_shots" => {"type" => "Array", "items" => { "type" => "string"}}
        }
      }
    }
  }.freeze

  SEQUENCES_SCHEMA = {
    "type" => "object",
    "required" => true,
    "patternProperties" => {
      "^[A-Z]" => {
        "type" => "object",
        "properties" => {
          "first_shot" => {"type" => "string", "required" => true},
          "shots" => SHOTS_SCHEMA
        }
      }
    }
  }.freeze


  GENERAL_SCHEMA = {
    "type" => "object",
    "properties" => {
      "messages" => MESSAGES_SCHEMA,
      "cookies" => COOKIES_SCHEMA,
      "sequences" => SEQUENCES_SCHEMA,
      "protocol_version" => {"type" => "int", "required" => true},
      "protogen_version" => {"type" => "int", "required" => true, "enum" => [1]}
    }
  }.freeze


  class Parser
    # This function will ensure that the json input document was correctly formed

    def self.run
      puts "Reading configuration and setting up the parser"
      default_conf_file = File.join('config', 'config.json')
      unless File.exist?(default_conf_file)
        raise Error::ConfigurationFileError.new("Can not find the default configuration file at #{default_conf_file}")
      end
      begin
        default_conf = JSON.parse(File.open(default_conf_file).read)['default']
      rescue JSON::ParserError => e
        raise Error::ConfigurationFileError.new("Error when JSON-parsing the default configuration file at #{default_conf_file}: #{e.message}")
      end
      Env.merge!(default_conf)

      unless File.exist?(Env['conf_file_path'])
        raise Error::ConfigurationFileError.new("Can not find configuration file at #{Env['conf_file_path']}")
      end
      conf_file = File.open(Env['conf_file_path'])

      begin
        configuration = JSON.parse(conf_file.read)
      rescue JSON::ParserError => e
        raise Error::ConfigurationFileError.new("Error when JSON-parsing the configuration file at #{Env['conf_file_path']}: #{e.message}")
      end

      # Configuration validation
      if configuration['server_output_directory']
        validation_errors = JSON::Validator.fully_validate(SERVER_CONF_SCHEMA, configuration, :validate_schema => true)
        if validation_errors.size > 0
          raise ConfigurationFileError.new("The configuration file do not follow the correct schema: #{SERVER_CONF_SCHEMA.inspect}. Errors: #{validation_errors.inspect}.")
        end
      elsif configuration['device_output_directory']
        validation_errors = JSON::Validator.fully_validate(DEVICE_CONF_SCHEMA, configuration, :validate_schema => true)
        if validation_errors.size > 0
          raise ConfigurationFileError.new("The configuration file do not follow the correct schema: #{DEVICE_CONF_SCHEMA.inspect}. Errors: #{validation_errors.inspect}.")
        end
      else
        raise Error::ConfigurationFileError.new("No output directory was given (set the 'server_output_directory' or 'device_output_directory' key in the configuration file)")
      end
      Env.merge!(configuration)
      use_protobuf, use_msgpack = false,false
      Env['plugins'].each do |plugin_name|
        if /protobuf/.match(plugin_name)
          puts "Will use protobuf because of plugin #{plugin_name}"
          use_protobuf = true
        end
        if /msgpack/.match(plugin_name)
          puts "Will use protobuf because of plugin #{plugin_name}"
        end
      end
      if use_protobuf && use_msgpack
        Error::PluginError.new('Conflict: two plugins found using msgpack and protobuf. You can use only one or the other.')
      elsif use_protobuf
        Env['ser_lang'] = 'protobuf'
        validation_errors = JSON::Validator.fully_validate(PROTOBUF_CONF_SCHEMA, configuration, :validate_schema => true)
        if validation_errors.size > 0
          raise ConfigurationFileError.new("The configuration file do not follow the correct Protobuf schema: #{PROTOBUF_CONF_SCHEMA.inspect}")
        end
      elsif use_msgpack
        Env['ser_lang'] = 'msgpack'
        validation_errors = JSON::Validator.fully_validate(MSGPACK_CONF_SCHEMA, configuration, :validate_schema => true)
        if validation_errors.size > 0
          raise ConfigurationFileError.new("The configuration file do not follow the correct msgpack schema: #{PROTOBUF_CONF_SCHEMA.inspect}. Errors: #{validation_errors.inspect}.")
        end
      end

      puts "Reading protocol definition file"
      unless File.exist?(Env['input_path'])
        raise Error::ProtocolFileNotFound.new("Can not find protocol definition file at #{Env['input_path']}")
      end
      if File.zero?(Env['input_path'])
        raise Error::ProtocolFileEmpty.new("Found empty protocol definition file at #{Env['input_path']}")
      end

      begin
        input = JSON.parse(File.open(Env['input_path']).read)
      rescue JSON::ParserError => e
        raise Error::ProtocolFileParserError.new("Error when JSON-parsing the protocol definition file at #{Env['input_path']}: #{e.message}")
      end

      # General validation
      validation_errors = JSON::Validator.fully_validate(GENERAL_SCHEMA, input, :validate_schema => true)
      if validation_errors.size > 0
        raise Error::ProtocolDefinitionError.new("General schema validation failed, check your input file. Errors: #{validation_errors.inspect}.")
      end

      # Messages
      puts "Building the environment (messages and types)..."
      Env['messages'] = input['messages']
      puts "Found messages #{Env['messages'].keys.inspect}"
      declared_messages = []
      Env['fields'] = {}
      Env['sendable_messages'] = {'from_server' => [], 'from_device' => []}
      id = 0
      Env['messages'].each do |msg_name, msg_content|
        fields = []
        msg_content['_id'] = id
        id += 1
        msg_content.each do |field_name, field_content|
          next if /^[a-z]/.match(field_name).nil?
          raise Error::ProtocolDefinitionError.new("Unknown message type: '#{field_content['type']}' (in field '#{field_name}' of message '#{msg_name}')") unless [BASIC_TYPES, 'msgpack', declared_messages].flatten.include?(field_content['type'])
          fields << field_name
        end
        raise Error::ProtocolDefinitionError.new("Type declared more than once: '#{msg_name}'.") if [BASIC_TYPES, 'msgpack', declared_messages].flatten.include?(msg_name)
        declared_messages << msg_name
        Env['fields'][msg_name] = fields
        if msg_content['_way'] == 'toDevice' || msg_content['_way'] == 'both'
          Env['sendable_messages']['from_server'] << msg_name
        end
        if msg_content['_way'] == 'toServer' || msg_content['_way'] == 'both'
          Env['sendable_messages']['from_device'] << msg_name
        end
      end # Env['messages'].each do |msg_name, msg_content|

      Env['declared_types'] = declared_messages
      puts "Declared types: #{Env['declared_types']}"
      puts "Sendable messages: #{Env['sendable_messages']}"
      puts "Fields of each message: #{Env['fields'].inspect}"
      puts "Parsed messages: #{Env['messages'].inspect}"

      # Cookies
      puts "Building the environment (cookies)..."
      Env['cookies'] = input['cookies']
      Env['use_cookies'] = !Env['cookies'].nil? && !Env['cookies'].empty?
      if Env['use_cookies']
        puts "Creating cookies"
        Env['cookie_names']=Env['cookies'].keys
        Env['cookies'].each do |cookie_name, cookie_content|
          fields = []
          cookie_content.each do |field_name, field_content|
            next if /^[a-z]/.match(field_name).nil?
            raise Error::ProtocolDefinitionError.new("Unknown type: '#{field_content['type']}' (in cookie '#{cookie_name}')") unless (BASIC_TYPES.include?(field_content['type'])) # || declared_types.include?(field_content['type']))
            fields << field_name
          end
          Env['fields'][cookie_name] = fields
        end
        puts "Fields of each message, including cookies: #{Env['fields'].inspect}"
        puts "Cookies: #{Env['cookie_names'].inspect}"
      else
        puts "No cookies declared, will not use cookies"
      end


      # Sequences
      Env['sequences'] = input['sequences']
      messages = Env['messages']
      Env['callbacks'] = {}
      seq_id = 0

      Env['sequences'].each do |sequence_name, sequence_definition|
        sequence_definition['id'] = seq_id
        seq_id += 1

        # validation
        shots = sequence_definition['shots']
        raise Error::SequenceError.new("Sequence #{sequence_name}: first shot #{sequence_definition['first_shot']} is not declared.") unless shots.has_key?(sequence_definition['first_shot'])
        id = 0
        shots.each do |shot, shot_definition|
          case shot_definition['way']
          when 'toServer'
            unless Env['sendable_messages']['from_device'].include?(shot_definition['message_type'])
              raise Error::SequenceError.new("Sequence #{sequence_name} shot #{shot}: message type #{shot_definition['message_type']} in undefined or not sendable from the device")
            end
          when 'toDevice'
            unless Env['sendable_messages']['from_server'].include?(shot_definition['message_type'])
              raise Error::SequenceError.new("Sequence #{sequence_name} shot #{shot}: message type #{shot_definition['message_type']} in undefined or not sendable from the server")
            end
          else
            raise Error::SequenceError.new("Sequence #{sequence_name} shot #{shot}: way must be either 'toDevice' or 'toServer'")
          end

          if shot_definition.has_key?('next_shots')
            registered_types = []
            shot_definition['next_shots'].each do |next_shot|
              raise Error::SequenceError.new("Sequence #{sequence_name} shot #{shot}: next shot #{next_shot} is not defined.") unless shots.has_key?(next_shot)
              if registered_types.include?(shots[next_shot]['message_type'])
                raise Error::SequenceError.new("Sequence #{sequence_name} shot #{shot}: some of the defined next_shots have the same message type.")
              end
              registered_types << shots[next_shot]['message_type']
              raise Error::SequenceError.new("Sequence #{sequence_name} shot #{shot} must have different 'way' property than its next shot #{next_shot}") unless shots[next_shot]['way'] != shot_definition['way']
            end
          end

          # compute shot id (id order does not matter, it just have to be the same on device and server)
          shot_definition['id'] = id
          id += 1
        end

      end


      Env['protocol_version'] = compute_version_string
      puts "Protocol version: #{Env['protocol_version']}"
    end

    def self.compute_version_string
      # todo rewrite that
      # Marshaled copies of the hashes, just to be sure there are no modified values in the original hash
      messages_copy = Marshal.load( Marshal.dump(Env['messages']) )
      cookies_copy = Marshal.load( Marshal.dump(Env['cookies']) )

      messages_v = {}
      # Order of message declarations matters, so we don't sort the keys
      messages_copy.keys.each do |msg_name|
        messages_v[msg_name] = {}
        # Order of field declarations does not matter, so we sort the fields alphabetically
        messages_copy[msg_name].keys.sort.each do |field|
          next unless ( /^[a-z]/.match(field) || ['_way'].include?(field)) # we only keep pertinent fields (no description or callback names)
          field_content = {}
          if(/^[a-z]/.match(field))
            # Again, order of the field  options does not matter, we sort
            messages_copy[msg_name][field].keys.sort.each do |field_opt|
              next unless ['type', 'modifier', 'array'].include?(field_opt)
              field_content[field_opt] = messages_copy[msg_name][field][field_opt]
            end
          else
            field_content = messages_copy[msg_name][field]
          end
          messages_v[msg_name][field] = field_content
        end
      end

      cookies_v = {}
      # Order stuff for cookies is the same than for messages
      cookies_copy.keys.each do |cookie_name|
        cookies_v[cookie_name] = {}
        cookies_copy[cookie_name].keys.sort.each do |field|
          next unless ( /^[a-z]/.match(field) || ['_send_with', '_secure', '_validity_time'].include?(field))
          field_content = {}
          if(/^[a-z]/.match(field))
            cookies_copy[cookie_name][field].keys.sort.each do |field_opt|
              next unless ['type', 'modifier', 'array'].include?(field_opt)
              field_content[field_opt] = cookies_copy[cookie_name][field][field_opt]
            end
          else
            field_content = cookies_copy[cookie_name][field]
          end
          cookies_v[cookie_name][field] = field_content
        end
      end
      "\"#{Digest::SHA1.hexdigest(messages_v.to_s+cookies_v.to_s)[-6..-1]}\""
    end

  end
end

