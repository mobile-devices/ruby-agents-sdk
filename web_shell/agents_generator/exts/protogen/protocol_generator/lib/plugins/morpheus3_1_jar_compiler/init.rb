
module ProtocolGenerator
  module Generator
    class Morpheus31JarCompiler < GeneratorPlugin

      class << self
        include Rake::DSL
      end

      def self.run
        raise 'Missing key \'mdi_framework_jar\' in configuration' if Env['mdi_framework_jar'].nil?
        java_dirs = Env['java_package'].split('.')
        dir = File.join(Env['output_directory'],'device')
        java_path = File.join(dir,java_dirs)

        jar_file = File.join(dir,"#{Env['java_package']}.jar")

        jar jar_file => :compile do |t|
          t.files << JarFiles[dir, "**/*.class"]
          # t.main_class = 'org.whathaveyou.Main'
          t.manifest = {:version => '1.0.0'}
        end

        javac :compile => dir do |t|
          t.src << Sources[dir, "**/*.java"]
          t.classpath << Env['mdi_framework_jar']
          t.dest = dir
        end

        directory dir

        Rake.application[jar_file].invoke

        FileUtils.rm_r(File.join(dir, java_dirs.first), :secure => :true, :force => :true) unless Env['keep_java_source'] == true
      end

      @dependencies = []
      @priority = -5
      init
    end
  end # Generator
end # ProtocolGenerator