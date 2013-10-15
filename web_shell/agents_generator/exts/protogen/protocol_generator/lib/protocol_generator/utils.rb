
module ProtocolGenerator
  module Utils
    def self.render(erb_file, output_file, plugin=nil)
      generated_code = ERB.new(File.read(erb_file),nil,'-').result(binding)
      File.open(output_file, 'w') do |f|
        f.write generated_code
      end
    end
  end
end

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end