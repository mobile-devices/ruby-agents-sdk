module ProtocolGenerator
  module Generator
    class RubyCookiesEncryptBase < GeneratorPlugin
      def self.run(protocol_set)
        directory = protocol_set.config.get(:ruby, :temp_output_path)
        FileUtils.mkdir_p(directory) if !File.directory?(directory)
        Utils.render(File.join(@templates_dir,'cookiesencrypt.rb.erb'), File.join(directory,'cookiesencrypt.rb'), binding)
      end

      @dependencies = []
      init
    end
  end # Generator
end # ProtocolGenerator