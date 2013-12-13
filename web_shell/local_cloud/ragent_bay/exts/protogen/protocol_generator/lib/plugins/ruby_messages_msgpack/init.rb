module ProtocolGenerator
  module Generator
    class RubyMessageMsgPack < GeneratorPlugin
      def self.run(protocol_set)
        directory = protocol_set.config.get(:ruby, :temp_output_path)
        FileUtils.mkdir_p(directory) if !File.directory?(directory)
        Utils.render(File.join(@templates_dir,'messages.rb.erb'), File.join(directory,'messages.rb'), binding)
        Utils.render(File.join(@templates_dir,'protogen_messages.rb.erb'), File.join(directory,'protogen_messages.rb'), binding)
      end

      @dependencies = []
      @priority = 10
      init
    end
  end # Generator
end # ProtocolGenerator