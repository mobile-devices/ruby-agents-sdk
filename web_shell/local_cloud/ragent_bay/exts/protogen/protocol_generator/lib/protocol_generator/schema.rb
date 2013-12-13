module ProtocolGenerator

  BASIC_TYPES = ['int', 'nil', 'bool', 'float', 'bytes', 'string'].freeze
  MSGPACK2JAVA = {
      'int' => 'int',
      'nil' => 'null',
      'bool' => 'boolean',
      'float' => 'float',
      'bytes' => 'byte[]',
      'string' => 'String'
  }.freeze

  MSGPACK2RUBY = {
      'int' => 'Fixnum',
      'nil' => 'NilClass',
      'bool' => 'Boolean', # No bool in ruby... currently MSGPACK2RUBY is used only in docstrings so that's not a problem
      'float' => 'Float',
      'bytes' => 'bytes',
      'string' => 'String'
  }.freeze

  DEFAULT_TIMEOUT = {
    send: 60,
    receive: 60
  }

  AVAILABLE_CALLBACKS = [:received_callback, :ack_timeout_callback, :cancel_callback, :response_timeout_callback, :send_timeout_callback, :server_nack_callback, :send_success_callback, :server_error_callback] # make sure to update the SHOTS schema too, and the Java controller (dispatcher plugin) if relevant

  module Schema

    SERVER_CONF = {
      "type" => "object",
      'required' => true,
      "properties" => {
        "plugins" => {'type' => 'array', 'required' => true},
        "agent_name" => {'type' => 'string', 'required' => true},
        "message_size_limit" => {'type' => 'int', 'required' => true},
        "message_part_size" => {'type' => 'int', 'required' => true},
        "server_message_part_expiration_duration" => {'type' => 'int', 'required' => true},
        "generate_ruby_documentation" => {'type' => 'boolean', 'required' => false}
      }
    }.freeze

    DEVICE_CONF = {
      "type" => "object",
      'required' => true,
      "properties" => {
        "plugins" => {'type' => 'array', 'required' => true},
        "java_package" => {'type' => 'string', 'required' => true},
        "mdi_framework_jar" => {'type' => 'string', 'required' => false},
        "keep_java_source" => {'type' => 'bool', 'required' => false},
        "keep_java_jar" => {'type' => 'bool', 'required' => false},
        "agent_name" => {'type' => 'string', 'required' => true},
        "device_message_size_limit" => {'type' => 'int', 'required' => true},
        "device_message_part_expiration_duration" => {'type' => 'int', 'required' => true}
      }
    }.freeze

    MSGPACK_CONF = {}.freeze

    PROTOBUF_CONF = {
      "type" => "object",
      'required' => true,
      "properties" => {
        "proto_file_name" => {'type' => 'string', 'required' => true},
        "protobuf_jar" => {'type' => 'string', 'required' => true},
        "package_name" => {'type' => 'string', 'required' => true}
      }
    }.freeze

    FIELD = {
      'type' => 'object',
      'properties' => {
        'type' => {'type'=>'string', 'required' => true},
        'modifier' => {'type'=>'string', 'enum' => ['required', 'optional'], 'required' => true},
        'array' => {'type'=>'bool', 'required' => false},
        'docstring' => {'type'=>'string', 'required' => false}
      }
    }.freeze

    MESSAGES = {
      'type' => 'object',
      'required' => true,
      'properties' => {},
      "patternProperties" => {
        "^[A-Z]" => {
          'type' => 'object',
          'properties' => {
            '_description' => {'type' => 'string', 'required' => false},
            '_way' => {'type' => 'string', 'enum' => ['toServer', 'toDevice', 'both', 'none'], 'required' => true}
          },
          "patternProperties" => {
            "^[a-z]" => FIELD
          }
        }
      }
    }.freeze

    COOKIES = {
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
            "^[a-z]" => FIELD
          }
        }
      }
    }.freeze

    SHOTS = {
      "type" => "object",
      "required" => true,
      "patternProperties" => {
        "^[A-Z]" => {
          "type" => "object",
          "properties" => {
            "way" => {"type" => "string", "required" => true, "enum" => ['toDevice', 'toServer']},
            "message_type" => {"type" => "string", "required" => true},
            "next_shots" => {"type" => "Array", "items" => { "type" => "string"}},
            "timeouts" => {
              "type" => "object",
              "required" => false,
              "properties" => {
                "send" => {"type" => "int", "required" => false},
                "receive" => {"type" => "int", "required" => false}
              }
            },
            "received_callback" => {"type" => "string", "required" => true},
            "ack_timeout_callback" => {"type" => "string", "required" => false},
            "cancel_callback" => {"type" => "string", "required" => false},
            "response_timeout_callback" => {"type" => "string", "required" => false},
            "send_timeout_callback" => {"type" => "string", "required" => false},
            "server_nack_callback" => {"type" => "string", "required" => false},
            "send_success_callback" => {"type" => "string", "required" => false},
            "server_error_callback" => {"type" => "string", "required" => false},
            "retry_policy" => {
              "type" => "object",
              "required" => false,
              "properties" => {
                "delay" => {"required" => true, "type"=>"int"},
                "attempts" => {"required" => false, "type"=>"int"}
              }
            }
          }
        }
      }
    }.freeze

    SEQUENCES = {
      "type" => "object",
      "required" => true,
      "patternProperties" => {
        "^[A-Z]" => {
          "type" => "object",
          "properties" => {
            "first_shot" => {"type" => "string", "required" => true},
            "shots" => SHOTS
          }
        }
      }
    }.freeze


    GENERAL = {
      "type" => "object",
      "properties" => {
        "name" => {"type" => "string", "required" => true, "pattern" => "^[A-Z]"},
        "messages" => MESSAGES,
        "cookies" => COOKIES,
        "sequences" => SEQUENCES,
        "protocol_version" => {"type" => "int", "required" => true},
        "protogen_version" => {"type" => "int", "required" => true, "enum" => [1]},
        "generic_error_callback" => {"type" => "string", "required" => false}
      }
    }.freeze

  end

end