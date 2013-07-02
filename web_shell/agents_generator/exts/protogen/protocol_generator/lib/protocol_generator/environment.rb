
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

    def self.init
      @env['pg_config_path'] = File.join('config', 'config.json')
      @env['pg_config'] = JSON.load(File.open(@env['pg_config_path'], 'r'))
      ::ProtocolGenerator.version = @env['pg_config']['pg_version']
    end

    def self.clean
      @env = {}
    end
  end
end

Env = ProtocolGenerator::Environment.env

