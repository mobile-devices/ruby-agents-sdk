module ProtocolGenerator
  module Generator
    class RubyMessageMsgPack < GeneratorPlugin
      def self.run
        directory = File.join(Env['output_directory'], 'server', 'ruby')
        FileUtils.mkdir_p(directory) if !File.directory?(directory)
        Utils.render(File.join(@templates_dir,'messages.rb.erb'), File.join(directory,'messages.rb'))
      end

      @dependencies = []
      @priority = 10
      init
    end
  end # Generator
end # ProtocolGenerator