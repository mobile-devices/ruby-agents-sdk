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

  CONF_SCHEMA = {
    "type" => "object",
    'required' => true,
    "properties" => {
      "plugins" => {'type' => 'array', 'required' => true},
      "java_package" => {'type' => 'string', 'required' => true},
      "mdi_framework_jar" => {'type' => 'string', 'required' => false},
      "keep_java_source" => {'type' => 'bool', 'required' => false}
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
      'modifier' => {'type'=>'string', 'required' => true},
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
    'required' => false,
    'properties' => {},
    "patternProperties" => {
      "^[A-Z]" => {
        'type' => 'object',
        'properties' => {
          "_send_with" => { 'type' => 'Array', },
          "_secure" => { 'type' => 'string', 'enum' => ['high', 'low', 'none']},
          "_validity_time" => {'type' => 'int', 'required' => false}
          },
        "patternProperties" => {
          "^[a-z]" => FIELD_SCHEMA
        }
      }
    }
  }.freeze

  SEQUENCES_SCHEMA = {
    'type' => 'object',
    'required' => false,
    'properties' => {
      # FIXME
    }
  }.freeze

  GENERAL_SCHEMA = {
    "type" => "object",
    "properties" => {
      "protocol_version" => { 'type' => 'int', 'required' => true},
      "messages" => MESSAGES_SCHEMA,
      "cookies" => COOKIES_SCHEMA,
      "sequences" => SEQUENCES_SCHEMA
    }
  }.freeze


  class Parser
    # This function will ensure that the json input document was correctly formed

    def self.run
      default_conf = JSON.parse(File.open(File.join('config', 'config.json')).read)['default']
      Env.merge!(default_conf)

      configuration = JSON.parse(File.open(Env['conf_file_path']).read)

      # Configuration validation
      JSON::Validator.validate!(CONF_SCHEMA, configuration, :validate_schema => true)
      Env.merge!(configuration)
      use_protobuf, use_msgpack = false,false
      Env['plugins'].each do |plugin_name|
        use_protobuf = true if /protobuf/.match(plugin_name)
        use_msgpack = true if /msgpack/.match(plugin_name)
      end
      if use_protobuf && use_msgpack
        raise 'Conflict: two plugins found using msgpack and protobuf'
      elsif use_protobuf
        Env['ser_lang'] = 'protobuf'
        JSON::Validator.validate!(PROTOBUF_CONF_SCHEMA, configuration, :validate_schema => true)
      elsif use_msgpack
        Env['ser_lang'] = 'msgpack'
        JSON::Validator.validate!(MSGPACK_CONF_SCHEMA, configuration, :validate_schema => true)
      end

      input = JSON.parse(File.open(Env['input_path']).read)

      # Messages validation
      JSON::Validator.validate!(MESSAGES_SCHEMA, input['messages'], :validate_schema => true)
      Env['messages'] = input['messages']
      declared_messages = []
      Env['fields'] = {}
      Env['sendable_messages'] = []
      Env['messages'].each do |msg_name, msg_content|
        fields = []
        msg_content.each do |field_name, field_content|
          next if /^[a-z]/.match(field_name).nil?
          raise "Unknown message type: #{field_content['type']}" unless [BASIC_TYPES, 'msgpack', declared_messages].flatten.include?(field_content['type'])
          fields << field_name
        end
        raise "Type already declared: #{msg_name}" if [BASIC_TYPES, 'msgpack', declared_messages].flatten.include?(msg_name)
        declared_messages << msg_name
        Env['fields'][msg_name] = fields
        Env['sendable_messages'] << msg_name if msg_content['_way'] != 'none'

        # Only validation
        if ['toServer', 'both'].include?(msg_content['_way']) && msg_content['_server_callback'].nil?
          raise "Missing field _server_callback in #{msg_name}"
        end

        if ['toDevice', 'both'].include?(msg_content['_way']) && msg_content['_device_callback'].nil?
          raise "Missing field _device_callback in #{msg_name}" if msg_content['_device_callback'].nil?
        end
      end
      Env['declared_types'] = declared_messages

      # Cookies validation
      JSON::Validator.validate!(COOKIES_SCHEMA, input['cookies'], :validate_schema => true)
      Env['cookies'] = input['cookies']
      Env['use_cookies'] = !Env['cookies'].nil? && !Env['cookies'].empty?
      if Env['use_cookies']
        Env['cookie_names']=Env['cookies'].keys
        Env['cookies'].each do |cookie_name, cookie_content|
          fields = []
          cookie_content.each do |field_name, field_content|
            next if /^[a-z]/.match(field_name).nil?
            raise "Unknown type: #{field_content['type']}" unless (BASIC_TYPES.include?(field_content['type'])) # || declared_types.include?(field_content['type']))
            fields << field_name
          end
          Env['fields'][cookie_name] = fields
        end
      end


      Env['sequences'] = {}
      Env['messages'].each do |msg_name, msg_content|
        if msg_content['_way'] == 'toServer' || msg_content['_way'] == 'both'
          Env['sequences']["seq_#{msg_name}_dev"] = {
            'type' => '1shot.device',
            'message' => msg_name,
            'callback' => msg_content['_server_callback']
          }
        end

        if msg_content['_way'] == 'toDevice' || msg_content['_way'] == 'both'
          Env['sequences']["seq_#{msg_name}_srv"] = {
            'type' => '1shot.server',
            'message' => msg_name,
            'callback' => msg_content['_device_callback'],
            "timeout_calls" => msg_content['_timeout_calls'],
            "timeouts" => msg_content['_timeouts']
          }
        end

      end

      # JSON::Validator.validate!(SEQUENCES_SCHEMA, input['sequences'], :validate_schema => true)
      # Env['sequences'] = input['sequences']
      # The initial way of expressing sequences has been deactivated. Should
      # you want to use it again, be careful not to override the sequences
      # defined inside messages definitions (using _way, etc...)
      Env['use_sequences'] = !Env['sequences'].nil? && !Env['sequences'].empty?
      if Env['use_sequences']
        Env['msg_replies_dev'] = {}
        Env['msg_seq_dev'] = {}
        Env['msg_seq_srv'] = {} # TODO !
        Env['msg_indep'] = {}
        Env['msg_callbacks_dev'] = {}
        Env['timeout_callbacks_dev'] = []
        Env['sequences'].each do |name,seq|
          seq['timeouts'] ||= {}
          seq['timeout_calls'] ||= {}
          case seq['type']
          when '1shot.device'
            Env['msg_seq_dev'][seq['message']] = name
          when '1shot.server'
            Env['msg_seq_srv'][seq['message']] = name
            Env['msg_indep'][seq['message']] = {'callback' => seq['callback']}
            Env['msg_callbacks_dev'][seq['callback']] = seq['message']
          when 'q&a.device'
            Env['msg_seq_dev'][seq['message']] = name
            Env['msg_replies_dev'][seq['message']] = seq['answers']
            seq['answers'].each do |msg,callback| Env['msg_callbacks_dev'][callback] = msg end
          when 'q&a.server'
            Env['msg_seq_srv'][seq['message']] = name
            raise 'q&a.server TODO'
          else
            raise "Unimplemented sequence: #{seq['type']}"
          end
          seq['timeout_calls'].each{|tc| Env['timeout_callbacks_dev'] << "#{name}_#{tc}_timeout"} unless seq['timeout_calls'].nil?
        end
      end

      # General validation, just to be sure
      JSON::Validator.validate!(GENERAL_SCHEMA, input, :validate_schema => true)

      Env['protocol_version'] = input['protocol_version']
    end

  end
end

