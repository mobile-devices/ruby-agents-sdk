
module ProtocolGenerator
  module Generator
    class MDISDKVMServerRuby < GeneratorPlugin
      def self.run(protocol_set)
        tmp_server_directory = protocol_set.config.get(:ruby, :temp_output_path)

        Utils.render(File.join(@templates_dir, 'main.rb.erb'), File.join(tmp_server_directory, "protogen_apis.rb"), binding)

        if protocol_set.config.get(:ruby, :generate_documentation)
          YARD::Tags::Library.define_tag "ProtocolGenerator version", :protogen_version
          YARD::Tags::Library.define_tag "Protocol version", :protocol_version

          Dir.chdir(tmp_server_directory) do
            yard_task = YARD::Rake::YardocTask.new do |t|
              t.files   = ['*.rb']
              t.options = [
                "--output-dir", 'doc',
                "--api", "public",
                "--title", "#{protocol_set.config.get(:ruby, :agent_name)} generated code documentation, Protocol Generator #{protocol_set.config.get(:global, :pg_version)}"
              ]
            end
            Rake.application[yard_task.name].invoke
          end
        end

        output_directory = protocol_set.config.get(:ruby, :output_path)
        FileUtils.mkdir_p(output_directory)
        FileUtils.mv(Dir.glob(File.join(tmp_server_directory, '*.rb')), output_directory, :force => true)
        FileUtils.mv(Dir.glob(File.join(tmp_server_directory, 'doc')), output_directory, :force => true)
        FileUtils.rm_r(tmp_server_directory, :secure => true)
      end

      @dependencies = [
        :ruby_codec_msgpack,
        :ruby_cookiesencrypt_base,
        :ruby_messages_msgpack,
        :ruby_passwdgen_redis,
        :ruby_splitter_redis,
        :ruby_sequences
      ]
      @priority = -10
      init
    end
  end # Generator
end # ProtocolGenerator
