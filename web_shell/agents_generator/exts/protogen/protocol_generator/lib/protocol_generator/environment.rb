
module ProtocolGenerator
  def self.version
    @@version
  end

  def self.version= pg_v
    @@version = pg_v
  end

  class Environment
    class << self
      attr_accessor :env
    end
    @env = {}

    def self.init (proto_file_path, conf_file_path, output_directory)
      @env['pg_config_path'] = File.join('config', 'config.json')
      @env['pg_config'] = JSON.load(File.open(@env['pg_config_path'], 'r'))
      ::ProtocolGenerator.version = @env['pg_config']['pg_version']
      @env['input_path'] = proto_file_path
      @env['conf_file_path'] = conf_file_path
      @env['output_directory'] = output_directory
    end

    def self.clean
      @env = {}
    end
  end
end

Env = ProtocolGenerator::Environment.env

