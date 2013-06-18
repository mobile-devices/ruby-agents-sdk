module ProtocolGenerator
  module Generator
    class Morpheus31MessagesMsgPack < GeneratorPlugin
      def self.nullvalue(type, is_array)
        if is_array
          'null'
        else
          case type
          when 'int' then '0'
          when 'float' then '0.0f'
          when 'bool' then false
          else
            'null'
          end
        end
      end
      def self.run
        Env['java_messages_class'] = "MDIMessages"
        Env['java_message_parent_class'] = 'AbstractMessage'
        java_path = Env['java_package'].split('.')
        dir = File.join(Env['output_directory'],'device')
        FileUtils.mkdir_p(File.join(dir,java_path))
        Utils.render(File.join(@templates_dir, 'MDIMessages.java.erb'), File.join(Env['output_directory'],'device',java_path,"MDIMessages.java"),self)
      end

      @dependencies = []
      @priority = 10
      init
    end
  end # Generator
end # ProtocolGenerator
