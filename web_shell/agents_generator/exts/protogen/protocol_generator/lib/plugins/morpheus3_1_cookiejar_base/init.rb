module ProtocolGenerator
  module Generator
    class Morpheus31CookieJarBase < GeneratorPlugin
      def self.run
        java_path = Env['java_package'].split('.')
        dir = File.join(Env['output_directory'],'device')
        FileUtils.mkdir_p(dir) if !File.directory?(dir)
        FileUtils.mkdir_p(File.join(dir,java_path))
        # CookieJar
        Utils.render(File.join(@templates_dir,'CookieJar.java.erb'), File.join(Env['output_directory'],'device',java_path,'CookieJar.java')) if Env['use_cookies']
      end

      @dependencies = []
      init
    end
  end # Generator
end # ProtocolGenerator
