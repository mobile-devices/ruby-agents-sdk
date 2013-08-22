#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

# defines the tests results for a given agent (identified by his name)
class TestsResultsForAgent

  attr_reader :name, :examples, :duration, :example_count, :failure_count, :pending_count, :reason

  def initialize(name, tests_results)
    @name = name
    @examples = []
    if tests_results.has_key?('examples')
      tests_results['examples'].each do |example|
        @examples.push(Example.new(example['full_description'], example['status'], example['file_path'], example['line_number']))
      end
    end
    @duration = tests_results['summary']['duration']
    @example_count = tests_results['summary']['example_count']
    @failure_count = tests_results['summary']['failure_count']
    @pending_count = tests_results['summary']['pending_count']
    if tests_results['summary_line'].include? "No tests subfolder found."
      @tests_run = false
      @reason = "No 'tests' subfolder was found in your agent main folder."
    else
      @tests_run = true
    end
  end

  def tests_run?
    @tests_run
  end

end

# this class is used in example.erb for HTML rendering
# its definition is dictated by the .erb template
class Example

  attr_reader :full_description, :status, :file_path, :line_number, :exception, :index

  def initialize(full_description, status, file_path, line_number, index, exception = nil)
    @full_description = full_description
     if status == "passed" || status == "failed" || status == "pending"
      @status = status
    else
      raise ArgumentError("status can be only 'passed', 'failed' or 'pending'")
    end
    @file_path = file_path
    @line_number = line_number.to_i
    @index = index.to_i

    unless exception.nil?
      if status == "passed" || status == "pending"
        raise ArgumentError("can not have an exception for the test if the test has not failed")
      end
      @exception = exception # exception is a hash with keys class, message, backtrace
    end
  end

end

def get_examples_list(tests_results)
  examples = tests_results[:examples]
  unless examples.nil?
    examples.map do |example|
      Example.new(example[:full_description], example[:status], example[:file_path],
        example[:line_number], example[:example_index], example[:exception])
    end
  end
end