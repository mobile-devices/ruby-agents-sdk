module ProtocolGenerator
  module Generator
    class RubyCookiesSplitterRedis < GeneratorPlugin
      def self.run
        directory = File.join(Env['output_directory'], 'server', 'ruby')
        FileUtils.mkdir_p(directory) if !File.directory?(directory)
        Utils.render(File.join(@templates_dir,'splitter.rb.erb'), File.join(directory,'splitter.rb'))
      end

      @dependencies = []
      init
    end
  end # Generator
end # ProtocolGenerator