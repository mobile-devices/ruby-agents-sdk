module ProtocolGenerator
  module Generator
    class RubyMessageProtobuf < GeneratorPlugin
      def self.run
        proto_file = File.join(Env['output_directory'], 'messages.proto')
        ruby_out = File.join(Env['output_directory'],'server','ruby')
        FileUtils.mkdir_p(ruby_out)
        str_exec = "rprotoc  --out #{ruby_out} #{proto_file}"
        `#{str_exec}`
      end

      @dependencies = [:main_messages_protobuf]
      init
    end
  end # Generator
end # ProtocolGenerator