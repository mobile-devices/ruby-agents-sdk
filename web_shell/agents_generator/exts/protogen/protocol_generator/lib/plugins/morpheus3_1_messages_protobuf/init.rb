module ProtocolGenerator
  module Generator
    class Morpheus31MessageProtobuf < GeneratorPlugin
      def self.run
        Env['java_messages_class'] = "MDIMessages"
        Env['java_message_parent_class'] = 'com.google.protobuf.GeneratedMessage'
        proto_file = File.join(Env['output_directory'], 'messages.proto')
        java_out = File.join(Env['output_directory'], 'device')
        FileUtils.mkdir_p(java_out)
        `protoc #{proto_file} --java_out=#{java_out}`
      end

      @dependencies = [:main_messages_protobuf]
      init
    end
  end # Generator
end # ProtocolGenerator





