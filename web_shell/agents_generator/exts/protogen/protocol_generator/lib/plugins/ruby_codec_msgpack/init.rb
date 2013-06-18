module ProtocolGenerator
  module Generator
    class RubyCodecMsgPack < GeneratorPlugin
      def self.run
        directory = File.join(Env['output_directory'], 'server', 'ruby')
        FileUtils.mkdir_p(directory) if !File.directory?(directory)
        Utils.render(File.join(@templates_dir,'codec.rb.erb'), File.join(directory,'codec.rb'))
      end

      @dependencies = [:ruby_messages_msgpack]
      @priority = 9
      init
    end
  end # Generator
end # ProtocolGenerator