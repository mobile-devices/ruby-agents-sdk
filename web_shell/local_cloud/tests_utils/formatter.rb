require 'rspec'
require 'rspec/core/formatters/base_formatter'
require 'monitor'
require 'active_support/core_ext/hash/deep_dup'

module Tests

  # A formatter that maintains a hash representation of the current test status
  # This class is thread-safe.
  # You can at any moment call its method {#get_status} to retrieve a (frozen) hash holding the current test information.
  class Formatter < RSpec::Core::Formatters::BaseFormatter

    attr_reader :agent_name

    def initialize(output, agent_name)
      super(output)
      @lock = Monitor.new
      @status = {}
      @status[:agent_name] = agent_name
      @status[:start_time] = Time.now.strftime "%Y-%m-%d %H:%M:%S UTC%z"
      @status[:tested] = 0
      @status[:examples] = []
      @example_index = 0
      @status[:failed_count] = 0
      @status[:pending_count] = 0
      @status[:passed_count] = 0
      @status[:status] = 'scheduled'
      @agent_name = agent_name
    end

    # todo: return an actual object
    # @param [Interger] min_example_index omits from the result any example whose index is < to the provided one
    def get_status(min_example_index = -1)
      out = {}
      @lock.synchronize do
        out = @status.deep_dup
      end
      out[:examples].select! do |example|
        example[:example_index] >= min_example_index
      end
      out.freeze
    end

    def message(message)
      @lock.synchronize do
       (@status[:messages] ||= []) << message
     end
   end

   def start(example_count)
    @lock.synchronize do
      @example_count = example_count
      @status[:example_count] = @example_count
      @status[:status] = "started"
    end
  end

  def example_group_finished(example_group)
      # do nothing for now
    end

    def example_started(example)
      @lock.synchronize do
        examples << example
        @example_started_time = Time.now
      end
    end

    def example_finished(example)
      @lock.synchronize do
        @example_index += 1
        @status[:tested] += 1
        @status[:examples] << format_example(example, @example_index, (Time.now - @example_started_time).to_f)
      end
    end

    def example_passed(example)
      @lock.synchronize do
        @status[:passed_count] += 1
        example_finished(example)
      end
    end

    def example_pending(example)
      @lock.synchronize do
        @status[:pending_count] += 1
        example_finished(example)
      end
    end

    def example_failed(example)
      @lock.synchronize do
        @status[:failed_count] += 1
        example_finished(example)
      end
    end

    def dump_summary(duration, example_count, failure_count, pending_count)
      @lock.synchronize do
        super(duration, example_count, failure_count, pending_count)
        @status[:summary] = {
          :duration => duration,
          :example_count => example_count,
          :failure_count => failure_count,
          :pending_count => pending_count
        }
        @status[:summary_line] = summary_line(example_count, failure_count, pending_count)

        dump_profile unless mute_profile_output?(failure_count)
      end
    end

    def summary_line(example_count, failure_count, pending_count)
      @lock.synchronize do
        summary = pluralize(example_count, "example")
        summary << ", " << pluralize(failure_count, "failure")
        summary << ", #{pending_count} pending" if pending_count > 0
        summary
      end
    end

    def close
      @lock.synchronize do
        if @status[:tested] == @status[:example_count]
          @status[:status] = "finished"
        else
          @status[:status] = "aborted"
        end
      end
    end

    def set_exception(e)
      @status[:status] = "exception"
      @status[:exception] = { :class => e.class.name,
                              :message => e.message,
                              :backtrace => e.backtrace }
                        
    end

    private
    def format_example(example, index, duration)
      hash = {
        :description => example.description,
        :full_description => example.full_description,
        :status => example.execution_result[:status],
        :file_path => example.metadata[:file_path],
        :line_number  => example.metadata[:line_number],
        :duration => duration,
        :example_index => index
      }
      if e = example.exception
        hash[:exception] =  {
          :class => e.class.name,
          :message => e.message,
          :backtrace => e.backtrace,
        }
      end
      hash
    end

    def dump_profile
      @lock.synchronize do
        @status[:profile] = {}
        dump_profile_slowest_examples
        dump_profile_slowest_example_groups
      end
    end

    def dump_profile_slowest_examples
      @status[:profile] = {}
      sorted_examples = slowest_examples
      @status[:profile][:examples] = sorted_examples[:examples].map do |example|
        format_example(example).tap do |hash|
          hash[:run_time] = example.execution_result[:run_time]
        end
      end
      @status[:profile][:slowest] = sorted_examples[:slows]
      @status[:profile][:total] = sorted_examples[:total]
    end

    def dump_profile_slowest_example_groups
      @status[:profile] ||= {}
      @status[:profile][:groups] = slowest_groups.map do |loc, hash|
        hash.update(:location => loc)
      end
    end
  end
end