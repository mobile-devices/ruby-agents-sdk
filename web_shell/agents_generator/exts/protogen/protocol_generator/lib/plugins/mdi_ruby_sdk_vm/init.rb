
module ProtocolGenerator
  module Generator
    class MDIRubySDKVM < GeneratorPlugin
      def self.run
        raise 'Missing key \'server_output_directory\' in configuration' if Env['server_output_directory'].nil?
        raise 'Missing key \'device_output_directory\' in configuration' if Env['device_output_directory'].nil?

        server_directory = File.join(Env['output_directory'], 'server', 'ruby')
        device_directory = File.join(Env['output_directory'], 'device')

        Utils.render(File.join(@templates_dir, 'main.rb.erb'), File.join(server_directory, "protogen_apis.rb"))

        FileUtils.mkdir_p(Env['server_output_directory'])
        FileUtils.mkdir_p(Env['device_output_directory'])
        FileUtils.mv(Dir.glob(File.join(server_directory, '*.rb')), Env['server_output_directory'], :force => true)
        FileUtils.mv(Dir.glob(File.join(device_directory, "*")), Env['device_output_directory'], :force => true)
        FileUtils.rm_r(Env['output_directory'], :secure => true)
      end

      @dependencies = [
        :morpheus3_1_codec_msgpack,
        :morpheus3_1_cookiejar_base,
        :morpheus3_1_dispatcher_base,
        :ruby_codec_msgpack,
        :ruby_cookiesencrypt_base,
        :ruby_messages_msgpack,
        :ruby_passwdgen_redis,
        :morpheus3_1_jar_compiler,
      ]
      @priority = -10
      init
    end
  end # Generator
end # ProtocolGenerator