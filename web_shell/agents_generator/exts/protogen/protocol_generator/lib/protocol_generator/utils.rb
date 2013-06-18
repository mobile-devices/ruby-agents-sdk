
module ProtocolGenerator
  module Utils
    def self.render(erb_file, output_file, plugin=nil)
      File.open(output_file, 'w') do |f|
        f.write ERB.new(File.read(erb_file),nil,'-').result(binding)
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

# class Sequence
#   attr_reader :raw, :first_msg, :last_msg
#   def initialize input_sequence
#     @raw = input_sequence
#     test_first = /^Device->Server:(.*)$/.match(input_sequence.first)
#     raise "First interaction not correctly formated in : #{name}" if test_first.nil? || !Env['input']['messages'].keys.select{|msg| Env['input']['messages'][msg]['_sendable']}.include?(test_first[1])
#     @first_msg = test_first[1]
#     if input_sequence.size > 1
#       test_last = /^Server->Device:(.*)$/.match(input_sequence.last)
#       raise "Return interaction not correctly formated in : #{name}" if test_last.nil? || !Env['input']['messages'].keys.select{|msg| Env['input']['messages'][msg]['_sendable']}.include?(test_last[1])
#       @last_msg = test_last[1]
#     end
#   end
# end