
module ProtocolGenerator
  module Generator

    # Abstract class
    class GeneratorPlugin
      class << self
        attr_reader :dependencies, :priority
        def init
          name = Env['tmp_plugin_name'].to_sym
          @templates_dir = File.join('lib', 'plugins', name.to_s, 'templates')
          @priority ||= 0
          @dependencies ||= []
          GENERATORS.merge!({name => self})
        end
      end
    end

    GENERATORS = {}

    class Manager
      def self.init_plugins
        Dir.foreach(File.join('lib', 'plugins')) do |dir_name|
          plugin_dir = File.join('plugins', dir_name)
          next unless dir_name != '.' && dir_name != '..' && File.directory?(File.join('lib', 'plugins', dir_name))
          Env['tmp_plugin_name'] = dir_name
          require File.join('plugins', dir_name, 'init.rb')
        end
      end

      def self.run(generator_list)
        @@done = []
        generator_list.sort{|a,b| GENERATORS[b].priority <=> GENERATORS[a].priority }.each do |generator|
          missing_deps = GENERATORS[generator].dependencies-GENERATORS.keys
          raise "Missing plugin(s): #{missing_deps} for #{generator}" unless missing_deps.size == 0
          launch_generator(generator)
        end
      end

      def self.launch_generator(gen_name)
        GENERATORS[gen_name].dependencies.each{|dep| launch_generator(dep)}
        unless @@done.include?(gen_name)
          puts "Running #{gen_name} plugin"
          GENERATORS[gen_name].run
          @@done << gen_name
        end
      end

      init_plugins
    end

  end # Generator
end # ProtocolGenerator
