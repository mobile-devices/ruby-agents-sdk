#!/usr/bin/ruby -w

#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'json'

require 'redcarpet'
require 'net/http'
require_relative 'lib/readcarpet_overload'
require_relative 'lib/agents'
require_relative 'lib/documentation'
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

#=========================================================================================
get '/' do
 redirect('/projects')
end

get '/projects' do
  @active_tab='projects'

  @action_popup = check_version_change_to_user
  agents_altered
  @agents = agents
  # cron
  update_cron_tasks
  # popup error
  @error_popup_msg = flash[:popup_error]


  p "Doing projects with #{is_show_more_stats} show more stat"

  erb :projects
end

get '/doc' do
  @active_tab='doc'

  render_documentation(sdk_doc_md)
  erb :doc
end

get '/patch_note' do
  @active_tab='patch_note'

  render_documentation(sdk_patch_note_md)
  erb :patch_note
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

  p "restart server with params=#{params}"

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
  content_type :json
  {crash:(PUNK.gen_server_crash_title != ''), running:(PUNK.is_ruby_server_running)}.to_json
end

get '/gen_sdk_log_buttons' do
  erb :logSdkButtons, layout: false
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

  erb :project_basic_stats, layout: false
end


#=========================================================================================
get '/reminder_show' do
  set_reminder_hidden(false)
  redirect('/projects')
end

get '/reminder_hide' do
  set_reminder_hidden(true)
  redirect('/projects')
end


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
  redirect("/tests_results?#{q}")
end


get '/tests_results' do
  @agents = params['agents']
  erb :tests
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
  output_file_path = "/home/vagrant/ruby_workspace/sdk_logs/tests_#{params['agent']}.log"

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
  return {"html" => html_to_append, "max_index" => test_status[:max_index], "status" => test_status[:status],
   "failed_count" => test_status[:failed_count], "passed_count" => test_status[:passed_count],
   "pending_count" => test_status[:pending_count], "example_count" => test_status[:example_count], "start_time" => test_status[:start_time]}.to_json
 end


# Possible test status for an agent
# "not scheduled" -> test neither started nor scheduled
# "no tests subfolders" -> test was shceduled but no 'tests' subfolfer was found
# "scheduled" -> test scheduled, but not started
# "started"
# "finished"
