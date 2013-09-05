#!/usr/bin/ruby -w

#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'json'

require 'net/http'
require_relative 'lib/agents'
require_relative 'lib/logs_getter'
require_relative 'lib/net_http'
require_relative 'lib/erb_config'
require_relative 'lib/tests'

require_relative 'lib/un_punkabe'

require_relative '../agents_generator/agents_mgt'
include GEN

require 'sinatra'
set :bind, '0.0.0.0'
set :port, '5000'

require 'rack/flash'
enable :sessions
use Rack::Flash

`bundle exec yardoc`

def print_ruby_exception(e)
  stack=""
  e.backtrace.take(20).each { |trace|
    stack+="  >> #{trace}\n"
  }
  CC.logger.error("  RUBY EXCEPTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n >> #{e.inspect}\n\n#{stack}\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
end

# define HTML escaping in templates
# useful for displaying stack traces that can contain nasty HTML characters
# see http://www.sinatrarb.com/faq.html#escape_html
helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

def last_version_path
  @last_version_launched_path ||= '.last_version'
end
# if the version has changed or first time, goto documentation or patch note page
def check_version_change_to_user
  action = 0
  if !(File.exist?(last_version_path))
    action = 1
  else
    current_v = File.read(last_version_path)
    if (current_v.length > 5 && get_sdk_version.length > 5)
      if current_v[0..5] != get_sdk_version[0..5]
        action = 2
      end
    end
  end
  File.open(last_version_path, 'w') { |file| file.write(get_sdk_version) }
  action
end

#=========================================================================================
get '/' do
 redirect('/projects')
end

get '/projects' do
  @active_tab='projects'

  @action_popup = check_version_change_to_user
  # agents
  agents_altered
  @agents = agents
  # stats
  update_sdk_stats
  @cur_sdk_stat = sdk_stats
  # cron
  update_cron_tasks
  # popup error
  @error_popup_msg = flash[:popup_error]

  puts "TOTO: #{@agents.inspect}"


  p "Doing projects with #{is_show_more_stats} show more stat"

  erb :projects
end

get '/doc' do
  redirect('doc/_index.html')
end

get '/patch_note' do
  redirect("doc/file.patch_notes.html")
end

get '/logSdk' do
  @active_tab='logSdk'
  erb :logSdk
end

get '/logSdkAgents' do
  @active_tab='logSdkAgents'
  erb :logSdkAgents
end

get '/logSdkAgentsPunk' do
  @active_tab='logSdkAgentsPunk'
  erb :logSdkAgentsPunk
end

get '/unit_tests' do
  @active_tab = "unit_tests"
  @agents = get_last_mounted_agents
  erb :tests
end



get '/reset_daemon_server_log' do
  if File.exist?(log_server_path)
    File.delete(log_server_path)
  end
  redirect('/logSdk')
end

get '/reset_ruby_agent_sdk_server_log' do
  if File.exist?(log_agents_path)
    File.delete(log_agents_path)
  end
  redirect('/logSdkAgents')
end

#=========================================================================================
post '/agents/:agent_name/start' do
  agent = agents.fetch(params[:agent_name])
  start_agent(agent)
  redirect('/projects')
end

post '/agents/:agent_name/stop' do
  agent = agents.fetch(params[:agent_name])
  stop_agent(agent)
  redirect('/projects')
end

post '/create_agents' do
  add_new_agent(params[:agent][:name])

  redirect('/projects')
end

get '/restart_server' do



  if params['reset_logs'] == 'on'
    if File.exist?(log_server_path)
      File.delete(log_server_path)
    end
    if File.exist?(log_agents_path)
      File.delete(log_agents_path)
    end
    set_reset_log_checked(true)
  else
    set_reset_log_checked(false)
  end

  $server_run_id = rand
  p "restart server with params=#{params} and id #{$server_run_id}"

  File.open('/tmp/should_mdi_server_run_id', 'w') { |file| file.write($server_run_id) }

  # launch in a new thread to avoid being stuck here
  thread = Thread.start {
    `cd ../local_cloud; ./local_cloud.sh restart`
  }

  p "redirecting to #{params['redirect_to']}"
  if params['redirect_to']
    redirect(params['redirect_to'])
  else
    redirect('/projects')
  end

end

#======================== AJAX DYN GEN ===================================================

get '/gen_ruby_server_reboot' do
  begin
    code = Net::HTTP.get_response(URI.parse('http://localhost:5001/is_alive')).code
  rescue Exception => e
    code = 503
  end
  content_type :json
  {crash:(PUNK.gen_server_crash_title != ''), running:("#{code}" == "200")}.to_json
end

get '/gen_sdk_log_buttons' do
  erb :gen_log_buttons, layout: false
end

get '/gen_basic_stats' do

  # stats
  update_sdk_stats

  time = sdk_stats['uptime']
  if time != nil
    hours = (time/3600).to_i
    minutes = (time/60 - hours * 60).to_i
    seconds = (time - (minutes * 60 + hours * 3600))
    hours = hours.to_i
    minutes = minutes.to_i
    seconds = seconds.to_i
    $uptime_str = "#{hours}h #{minutes}min #{seconds}s"

  else
    $uptime_str = '??'
  end

  erb :gen_projects_basic_stats, layout: false
end

get '/gen_agents_basic_stats' do

  # stats
  update_sdk_stats

end

get '/gen_main_display' do

  @agents = agents

  update_sdk_stats
  @cur_sdk_stat = sdk_stats
  # cron
  # update_cron_tasks

  if is_show_more_stats == 'true'
    erb :gen_sdk_stats_to_array, layout: false
  else
    erb :gen_agents_table, layout: false
  end
end

#=========================================================================================

get '/extented_stats_show' do
  set_show_more_stats(true)
  redirect('/projects')
end

get '/extented_stats_hide' do
  set_show_more_stats(false)
  redirect('/projects')
end

get '/cron_tasks_visible_show' do
  set_cron_tasks_visible(true)
  redirect('/projects')
end

get '/cron_tasks_visible_hide' do
  set_cron_tasks_visible(false)
  redirect('/projects')
end

get '/log_show_server_show' do
  set_log_show_server(true)
  redirect('/logSdkAgentsPunk')
end

get '/log_show_server_hide' do
  set_log_show_server(false)
  redirect('/logSdkAgentsPunk')
end

get '/log_show_com_show' do
  set_log_show_com(true)
  redirect('/logSdkAgentsPunk')
end

get '/log_show_com_hide' do
  set_log_show_com(false)
  redirect('/logSdkAgentsPunk')
end


get '/log_show_process_show' do
  set_log_show_process(true)
  redirect('/logSdkAgentsPunk')
end

get '/log_show_process_hide' do
  set_log_show_process(false)
  redirect('/logSdkAgentsPunk')
end


get '/log_show_error_show' do
  set_log_show_error(true)
  redirect('/logSdkAgentsPunk')
end

get '/log_show_error_hide' do
  set_log_show_error(false)
  redirect('/logSdkAgentsPunk')
end

get '/clear_daemon_log' do
  if File.exist?(log_agents_path)
    `echo -ne ""> #{log_agents_path}`
  end

  redirect('/logSdkAgentsPunk#endlog')
end

post '/perform_cron_tasks' do
  begin
    task = JSON.parse(params['task'])
    puts "perform_cron_tasks: #{task}"
    p ''
    http_post('http://localhost:5001/remote_call', task)
  rescue JSON::ParserError => e
    flash[:popup_error] = "Error when parsing scheduled tasks, double-check your config/schedule.rb."
    puts "error when parsing cron tasks"
    print_ruby_exception(e)
  end

  redirect('/projects')
end

# ====== Tests ==============

post '/run_tests' do
  unless params.has_key?('agents')
    return halt(400, "'agents' parameter is mandatory")
  end
  q = Rack::Utils.build_nested_query(
    agents: params['agents']
  )
  # todo check HTTP return code before redirecting (risk of silencing an error)
  http_get("http://localhost:5001/start_tests?#{q}")
end

get '/stop_tests' do
  http_get("http://localhost:5001/stop_tests")
end

# return a piece of HTML to insert in the table of results with AJAX
get '/update_test_status' do
  content_type :json

  # basic validation
  unless params.has_key?('agent')
    halt(400, "You must provide the 'agent' parameter")
  end
  if params.has_key?("index")
    last_index = Integer(params["index"]) rescue nil
    halt(400, "'last_index' parameter must be an integer") unless last_index
    if last_index < 0
      halt(400, "'last index' parameter must be a positive integer")
    end
  end

  # read tests logs. As it is written with atomic_write there is no risk doing it even if RSpec is currenty writing to it.
  root_path = File.expand_path(File.dirname(__FILE__))
  log_path = File.expand_path(File.join(root_path, "..", "..", "logs"))
  output_file_path = File.join(log_path, "tests_#{params['agent']}.log")

  unless File.file?(output_file_path)
    return {status: "not scheduled"}.to_json
  end

  begin
    test_status = JSON.parse(File.read(output_file_path), {symbolize_names: true})
  rescue JSON::ParserError => e
    # this case may happen when the file exists but is empty
    # todo: this case should not happen, but in practise in does -> why ?
    # as a temporary fix I silently ignore this error, but it should return a 500 error instead:
    # halt(500, "ERROR: can not parse tests log file at " + output_file_path + " because of the following problem: " + e.message)
    return {status: "scheduled"}.to_json
  end

  if test_status[:status] == "scheduled" || test_status[:status] == "no tests subfolder"
    return test_status.to_json
  end

  if test_status[:status] == "aborted"
    @exception = test_status[:exception]
    html_to_append = erb :tests_aborted, :layout => false
    return test_status.merge!({html: html_to_append}).to_json
  end

  # todo edge cases (no examples run..)

  # If index parameter was given, we only keep the examples that were not sent before
  if params.has_key?("index")
    test_status[:examples].delete_if do |example|
      example[:example_index] <= last_index
    end
    # if there are no examples left, return immediately
    if test_status[:examples].size == 0
      test_status[:max_index] = last_index
      return test_status.to_json
    end
  end

  # find the maximum index of tests in the remaining examples
  example_with_max_index = test_status[:examples].max_by do |example|
    example[:example_index]
  end
  test_status[:max_index] = example_with_max_index[:example_index]

  index = 0
  index = params['index'] if params.has_key?('index')
  @examples = get_examples_list(test_status)
  if @examples.nil?
    html_to_append = ''
  else
    html_to_append = erb :example, :layout => false
  end
  res = {"html" => html_to_append,
    "max_index" => test_status[:max_index], "status" => test_status[:status],
   "failed_count" => test_status[:failed_count], "passed_count" => test_status[:passed_count],
   "pending_count" => test_status[:pending_count], "example_count" => test_status[:example_count],
   "start_time" => test_status[:start_time]}
   res.merge!({"duration" => test_status[:summary][:duration]}) unless test_status[:summary].nil?
   res.to_json
 end

# Possible test status for an agent
# "not scheduled" -> test neither started nor scheduled
# "no tests subfolders" -> test was shceduled but no 'tests' subfolfer was found
# "scheduled" -> test scheduled, but not started
# "started"
# "finished"
# "interrupted"
# 'aborted' rspec threw an exception

# read the log file containing tests results for the given agent
# and write it on the disk as HTML
# return the location where results were written
post '/save_tests_results' do
  unless params.has_key?('agent')
    return halt(400, "'agent' parameter is mandatory")
  end
  root_path = File.expand_path(File.dirname(__FILE__))
  log_path = File.expand_path(File.join(root_path, "..", "..", "logs"))
  output_file_path = File.join(log_path, "tests_#{params['agent']}.log")
  cloud_agents_path = File.expand_path(File.join(root_path, "..", "..", "cloud_agents"))
  unless File.file?(output_file_path)
    halt(400, "No tests results for agent #{params['agent']} at #{output_file_path}, impossible to save them.")
  end
  begin
    test_status = JSON.parse(File.read(output_file_path), {symbolize_names: true})
  rescue JSON::ParserError => e
    halt(500, "Error when parsing tests results log file: #{e.message}")
  end
  unless (test_status[:status] == "finished" || test_status[:status] == "started" || test_status[:status] == "interrupted")
    halt(400, "tests must have started before saving their results (current status: #{test_status[:status]})")
  end
  @examples = get_examples_list(test_status)
  if @examples.nil?
    @examples = [] # to avoid errors in erb template
  end
  @duration = test_status[:summary][:duration] unless test_status[:summary].nil?
  @summary = "#{test_status[:tested]} out of #{test_status[:example_count]} tests run (#{test_status[:failed_count]} failed, #{test_status[:pending_count]} not implemented)"
  @agent = params['agent']
  @date = test_status[:start_time]
  @git_info = get_git_status(File.join(cloud_agents_path, "#{params['agent']}"))
  @failed = test_status[:failed_count] > 0
  html = erb :export_tests, :layout => false
  output_directory = File.join(log_path, "tests_results", "#{params['agent']}")
  output_path = File.join(output_directory, "#{sanitize_filename(@date)}_#{params['agent']}.html")
  FileUtils.mkdir_p(output_directory)
  File.open(output_path, 'w') do |file|
    file.write(html)
  end
  output_path.gsub("/home/vagrant/", "")
end

# return a hash of agents with their current test status
# if an agent is not in the array status is "not started"
# assumption: logs that begin with "tests_" are logs produced
# by the SDK
get '/tests_status' do
  content_type :json
  root_path = File.expand_path(File.dirname(__FILE__))
  log_path = File.expand_path(File.join(root_path, "..", "..", "logs"))
  log_pattern = "tests_*.log"
  res = Dir.glob(File.join(log_path, log_pattern)).inject({}) do |acc, current_log|
    begin
      File.open(current_log, 'r') do |file|
        test_status = JSON.parse(file.read, {symbolize_names: true})
        acc[current_log] = test_status[:status]
      end
    rescue JSON::ParserError => e
      puts "Error when parsing the content of " + current_log + ": " + e.message
    end
    acc
  end
  # rename ".../tests_agent.log" keys to "agent" (in place)
  res.keys.each do |k|
    res[ k.gsub(File.join(log_path, "tests\_"), "").gsub("\.log", "") ] = res.delete(k)
  end
  return res.to_json
end