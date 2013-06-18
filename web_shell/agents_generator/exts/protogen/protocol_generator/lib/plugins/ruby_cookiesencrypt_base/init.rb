module ProtocolGenerator
  module Generator
    class RubyCookiesEncryptBase < GeneratorPlugin
      def self.run
        directory = File.join(Env['output_directory'], 'server', 'ruby')
        FileUtils.mkdir_p(directory) if !File.directory?(directory)
        Utils.render(File.join(@templates_dir,'cookiesencrypt.rb.erb'), File.join(directory,'cookiesencrypt.rb')) if Env['use_cookies']
      end

      @dependencies = []
      init
    end
  end # Generator
end # ProtocolGenerator