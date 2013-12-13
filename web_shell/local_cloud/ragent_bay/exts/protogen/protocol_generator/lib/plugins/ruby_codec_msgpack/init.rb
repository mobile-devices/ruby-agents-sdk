module ProtocolGenerator
  module Generator
    class RubyCodecMsgPack < GeneratorPlugin
      def self.run(protocol_set)
        directory = protocol_set.config.get(:ruby, :temp_output_path)
        FileUtils.mkdir_p(directory) if !File.directory?(directory)
        Utils.render(File.join(@templates_dir,'codec.rb.erb'), File.join(directory,'codec.rb'), binding)
      end

      @dependencies = [:ruby_messages_msgpack]
      @priority = 9
      init
    end
  end # Generator
end # ProtocolGenerator