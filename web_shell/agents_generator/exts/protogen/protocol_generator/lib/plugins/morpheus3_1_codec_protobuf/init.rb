module ProtocolGenerator
  module Generator
    class Morpheus31CodecProtobuf < GeneratorPlugin
      def self.run
        java_path = Env['java_package'].split('.')
        dir = File.join(Env['output_directory'],'device')
        FileUtils.mkdir_p(File.join(dir,java_path))
        Utils.render(File.join(@templates_dir, 'Codec.java.erb'), File.join(Env['output_directory'],'device',java_path,'Codec.java'))
      end

      @dependencies = [:morpheus3_1_messages_protobuf]
      init
    end
  end # Generator
end # ProtocolGenerator