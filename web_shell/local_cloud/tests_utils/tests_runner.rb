require 'rspec'
require 'singleton'
require 'thread'
require 'json'

class TestsRunner
  include Singleton

  def initialize
    @start_mutex = Mutex.new
    @stop_mutex = Mutex.new
    @thread_mutex = Mutex.new
    @root_path = File.expand_path(File.join(File.dirname(__FILE__), ".."))
    CC.logger.debug("root path: #{@root_path}")
    @log_path = File.expand_path(File.join(@root_path, "..", "..", "logs"))
    @cloud_agents_path = File.expand_path(File.join(@root_path, "..", "..", "cloud_agents"))
    CC.logger.debug("cloud age,ts: #{@cloud_agents_path}")
    @tester_thread = nil
    CC.logger.debug("Singleton TestsRunner created.")
  end

  # Start tests in background
  def start_tests(agents_array)
    CC.logger.debug("TestRunner instance: starting tests.")
    @start_mutex.synchronize do
      # stop previous tests
      stop_tests

      # create files so we indicate we are going to test the agents
      agents_array.each do |agent|
        test_path = File.join(@cloud_agents_path, "#{agent}", "tests")
        output_file_path = File.join(@log_path, "tests_#{agent}.log")
        if File.directory?(test_path)
          CC.logger.info("TestRunner instance: found test directory for agent #{agent} at #{test_path}")
          File.delete(output_file_path) if File.exist?(output_file_path)
          File.open(output_file_path, 'w') { |file| file.write({status: "scheduled"}.to_json) }
        else
          CC.logger.info("TestRunner instance: no test directory found for agent #{agent} at #{test_path}, skipping tests.")
          File.delete(output_file_path) if File.exist?(output_file_path)
          File.open(output_file_path, 'w') { |file| file.write({status: "no tests subfolder"}.to_json) }
        end
      end

      # Create a new tester thread
      # Assumption: the previous tester thread has been killed, no one is reading the output files
      @tester_thread = Thread.new(agents_array, @root_path, @cloud_agents_path, @log_path, @thread_mutex) do |agents, root_path, cloud_agents_path, log_path, mutex|
        mutex.synchronize do # todo is this mutex actually useful?
          CC.logger.debug(" --- in tester thread --- Starting tester thread.")
          libdir = File.join(root_path, "tests_utils") # so the user can write "require 'test_helper'"
          $LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
          agents.each do |agent|
            test_path = File.join(cloud_agents_path, "#{agent}", "tests")
            output_file_path = File.join(log_path, "tests_#{agent}.log")
            if File.directory?(test_path)
              CC.logger.debug(" --- in tester thread --- Starting tests for #{agent}.")
              begin
                RSpec::Core::Runner.run([test_path,
                  "--require", File.join(root_path, "tests_utils", "json_tests_writer.rb"), "--format", "JsonTestsWriter"],
                  $stderr, output_file_path)
              rescue Exception => e
                # the runner launched an exception itself
                # rspec doesn't catch exceptions that are not thrown in the body of a test
                # so for instance we could go here if a test file is incorectly formatted
                CC.logger.debug(" --- in tester thread --- caught exception while running tests: " + e.message)
                File.atomic_write(output_file_path) do |file|
                  file.write({status: "aborted",
                        exception: {
                          :class => e.class.name,
                          :message => e.message,
                          :backtrace => e.backtrace,
                        }
                      }.to_json)
                end # atomic_write
              end # rescue Exception
              CC.logger.debug(" --- in tester thread --- Tests for #{agent} finished.")
            end # if File.directory?(tests_folder)
          end # agents_array.each do |agent|
          CC.logger.debug(" --- in tester thread --- Tester thread returning.")
        end # mutex.synchronize do
      end # tester_thread = ...
      CC.logger.debug("TestRunner instance: tests started.")
    end # --- @start_mutex.synchronize do +++
  end #  def start_tests

  def stop_tests
    @stop_mutex.synchronize do
      CC.logger.debug("Killing tester thread...")
      unless @tester_thread.nil?
        Thread.kill(@tester_thread)
        @tester_thread.join
        @tester_thread = nil
        CC.logger.debug("Tester thread killed.")
      end
      # make sure we don't have any "scheduled" tests
      # the JSON tests writer will set the status of the current test to "interrupted"
      # but other scheduled tests wont be marked as cancelled
      log_pattern = "tests_*.log"
      res = Dir.glob(File.join(@log_path, log_pattern)).each do |current_log|
        begin
          file = File.open(current_log, 'r')
          test_status = JSON.parse(file.read, {symbolize_names: true})
        rescue JSON::ParserError => e
          CC.logger.warn("Error when parsing the content of " + current_log + ": " + e.message)
        ensure
          file.close
        end
        if test_status[:status] == "scheduled"
          File.delete(file)
        end
      end
    end
  end

end