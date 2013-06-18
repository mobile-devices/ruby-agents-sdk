module ProtocolGenerator
  module Generator
    class Morpheus31DispatcherBase < GeneratorPlugin
      def self.run
        java_path = Env['java_package'].split('.')
        dir = File.join(Env['output_directory'],'device')
        FileUtils.mkdir_p(dir) if !File.directory?(dir)
        FileUtils.mkdir_p(File.join(dir,java_path))
        Utils.render(File.join(@templates_dir,'Dispatcher.java.erb'), File.join(dir,java_path,'Dispatcher.java'))
        Utils.render(File.join(@templates_dir,'IMessageController.java.erb'), File.join(dir,java_path,'IMessageController.java'))
      end

      @dependencies = []
      init
    end
  end # Generator
end # ProtocolGenerator