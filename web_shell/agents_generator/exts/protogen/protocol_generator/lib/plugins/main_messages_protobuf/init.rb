module ProtocolGenerator
  module Generator
    class MainMessagesProtobuf < GeneratorPlugin
      def self.modifier(input)
        case input
        when "required"
          return "required"
        when "optional"
          return "optional"
        when "repeated"
          return "repeated"
        else
          raise "Modifier is missing or wrong: set required, optional or repeated"
        end
      end

      def self.generate_proto(messages,layer, erb_path)
        @messages=messages
        return ERB.new(File.read(File.join(@templates_dir, erb_path))).result(binding)
      end

      def self.run
        FileUtils.mkdir_p(Env['output_directory']) if !File.directory?(Env['output_directory'])
        @messages=Env["messages"]
        Env["messages"] = []
        Env["structure"] = @messages
        @messages.each do |key, value|
          Env["messages"] << key
        end
        Env['messages_tmp'] = @messages
        Utils.render(File.join(@templates_dir,'wrapper.proto.erb'), File.join(Env['output_directory'],'messages.proto'), self)
      end

      @dependencies = []
      init
    end
  end # Generator
end # ProtocolGenerator