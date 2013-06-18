module ProtocolGenerator
  module Generator
    class PasswordGeneratorRedis < GeneratorPlugin
      def self.run
        FileUtils.cp(File.join('lib', 'plugins', 'ruby_passwdgen_redis', 'templates', 'password-manager.rb'), File.join(Env['output_directory'], 'server', 'ruby'))
      end

      @dependencies = []
      init
    end
  end # Generator
end # ProtocolGenerator