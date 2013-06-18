module ProtocolGenerator
  module Generator
    class Morpheus31CodecMsgpack < GeneratorPlugin
      def self.run
        java_path = Env['java_package'].split('.')
        dir = File.join(Env['output_directory'],'device')
        FileUtils.mkdir_p(dir) if !File.directory?(dir)
        FileUtils.mkdir_p(File.join(dir,java_path))
        Utils.render(File.join(@templates_dir, 'Codec.java.erb'), File.join(Env['output_directory'],'device',java_path,'Codec.java'))
      end

      @dependencies = [:morpheus3_1_messages_msgpack]
      @priority = 9
      init
    end
  end # Generator
end # ProtocolGenerator
