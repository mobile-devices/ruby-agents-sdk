
module ProtocolGenerator
  module Generator
    class MDIRubyAgentEncoder < GeneratorPlugin
      def self.run
        raise 'Missing key \'ruby_agent_name\' in configuration' if Env['ruby_agent_name'].nil?
        directory = File.join(Env['output_directory'], 'server', 'ruby')
        FileUtils.mkdir_p(directory) if !File.directory?(directory)
        FileUtils.mkdir_p(File.join(directory, 'pg_code'))
        FileUtils.mv(Dir.glob(File.join(directory, '*.rb')), File.join(directory, 'pg_code'))
        FileUtils.mkdir_p(File.join(directory, 'handlers'))
        Utils.render(File.join(@templates_dir, 'agent_name_handler.rb.erb'), File.join(directory, 'handlers', "#{Env['ruby_agent_name'].underscore}_handler.rb"))
      end

      @dependencies = [:ruby_dispatcher_base, :ruby_passwdgen_redis]
      @priority = -10
      init
    end
  end # Generator
end # ProtocolGenerator