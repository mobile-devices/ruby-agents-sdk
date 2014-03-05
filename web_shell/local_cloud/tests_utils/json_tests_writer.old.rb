# see https://github.com/rspec/rspec-core/blob/master/lib/rspec/core/formatters/base_formatter.rb

require 'rspec'
require 'rspec/core/formatters/base_formatter'
# the active_support gem also defines an atomic write
# shloud we remove this gem, we'd need to have this feature
# require_relative 'atomic_write'
require 'json'

# Formatter for RSpec tests results
# This formatter maintain a inner hash (named output_hash) that holds the current tests results
# It writes this hash to a file (whose path is specified by the 'output' parameter) every X seconds
# even if the (only) writer writes in it during the reading.
class JsonTestsWriter < RSpec::Core::Formatters::BaseFormatter

  attr_reader :output_hash

  def initialize(output) # output is a a file path (a string)
    super(output)
    @output_hash = {}
    @writing_period = 5 # duration between two writings in the file in seconds.
    @time_last_write = Time.now.to_i - @writing_period
    @output_hash[:start_time] = Time.now.strftime "%Y-%m-%d %H:%M:%S UTC%z"
    @output_hash[:tested] = 0
    @output_hash[:examples] = []
    @example_index = 0
    @output_hash[:failed_count] = 0
    @output_hash[:pending_count] = 0
    @output_hash[:passed_count] = 0
  end

  def write_to_output(force = false)
    if (Time.now.to_i - @time_last_write > @writing_period) || force
      File.atomic_write(@output) do |file|
        file.write(@output_hash.to_json)
      end
      @time_last_write = Time.now.to_i
    end
  end

  def message(message)
    (@output_hash[:messages] ||= []) << message
  end

  def start(example_count)
    @example_count = example_count
    @output_hash[:example_count] = @example_count
    @output_hash[:status] = "started"
    write_to_output(true)
  end

  def example_group_finished(example_group)
    write_to_output
  end

  def example_started(example)
    examples << example
    @example_started_time = Time.now
  end

  def example_finished(example)
    @example_index += 1
    @output_hash[:tested] += 1
    @output_hash[:examples] << format_example(example, @example_index, (Time.now - @example_started_time).to_f)
    write_to_output
  end

  def example_passed(example)
    @output_hash[:passed_count] += 1
    example_finished(example)
  end

  def example_pending(example)
    @output_hash[:pending_count] += 1
    example_finished(example)
  end

  def example_failed(example)
    @output_hash[:failed_count] += 1
    example_finished(example)
  end

  def dump_summary(duration, example_count, failure_count, pending_count)
    super(duration, example_count, failure_count, pending_count)
    @output_hash[:summary] = {
      :duration => duration,
      :example_count => example_count,
      :failure_count => failure_count,
      :pending_count => pending_count
    }
    @output_hash[:summary_line] = summary_line(example_count, failure_count, pending_count)

    dump_profile unless mute_profile_output?(failure_count)
  end

  def summary_line(example_count, failure_count, pending_count)
    summary = pluralize(example_count, "example")
    summary << ", " << pluralize(failure_count, "failure")
    summary << ", #{pending_count} pending" if pending_count > 0
    summary
  end

  def close
    if @output_hash[:tested] == @output_hash[:example_count]
      @output_hash[:status] = "finished"
    else
      @output_hash[:status] = "interrupted"
    end
    write_to_output(true)
  end

  def dump_profile
    @output_hash[:profile] = {}
    dump_profile_slowest_examples
    dump_profile_slowest_example_groups
  end

  def dump_profile_slowest_examples
    @output_hash[:profile] = {}
    sorted_examples = slowest_examples
    @output_hash[:profile][:examples] = sorted_examples[:examples].map do |example|
      format_example(example).tap do |hash|
        hash[:run_time] = example.execution_result[:run_time]
      end
    end
    @output_hash[:profile][:slowest] = sorted_examples[:slows]
    @output_hash[:profile][:total] = sorted_examples[:total]
  end

  def dump_profile_slowest_example_groups
    @output_hash[:profile] ||= {}
    @output_hash[:profile][:groups] = slowest_groups.map do |loc, hash|
      hash.update(:location => loc)
    end
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
end