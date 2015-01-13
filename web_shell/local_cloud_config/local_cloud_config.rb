#!/usr/bin/ruby -w

#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'json'

require 'uri'
require 'net/http'
require 'securerandom'
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
  p "  RUBY EXCEPTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n >> #{e.inspect}\n\n#{stack}\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
end

# define HTML escaping in templates
# useful for displaying stack traces that can contain nasty HTML characters
# see http://www.sinatrarb.com/faq.html#escape_html
helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

def current_sdk_vm_base_version
  @current_sdk_vm_base_version_value ||= begin
    if File.exist?('/home/vagrant/.base_sdk_vm_version')
      File.read('/home/vagrant/.base_sdk_vm_version')
    else
      'abs'
    end
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


p "local_cloud_config started ! with vm base version = #{current_sdk_vm_base_version} and sdk version = #{get_sdk_version}"

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
  @cur_sdk_stats_full = sdk_stats_full
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
  # @active_tab='logSdk'
  # erb :logSdk
  logs_server_file_content.gsub("\n","</br>")
end

get '/logSdkAgents' do
  # @active_tab='logSdkAgents'
  # erb :logSdkAgents
  logs_agent_file_content.gsub("\n","</br>")
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

post '/make_package/:agent_name' do
  agent = agents.fetch(params[:agent_name])
  p "Make package of #{agent.name}"
  path = make_package_agent(agent)
  flash[:notice] = "Package generation successful for agent #{:agent_name} in file #{path}."
  redirect("/projects")
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
  add_new_agent(params[:agent][:name], params[:agent][:package])
  redirect('/projects')
end

get '/agents/:agent_name/configure' do
  @agent_name = params[:agent_name]
  p "about to configures #{@agent_name}"

  @cfg = {
    'io' => agent_io_configuration(@agent_name),
    'general' => agent_general_configuration(@agent_name)
  }


  erb :agent_configuration
end

post '/agents/:agent_name/set_configuration' do
  p params
  @agent_name = params[:agent_name]

  # ["submit", "save_config"]["io_input|0|id", "ed002b6311"]["io_input|0|accounts", "ALL_ACCOUNTS"]["io_input|0|filter_type", "track"]
  # ["io_input|0|track_fields", ""]["io_input|1|id", "02fe10187a"]["io_input|1|accounts", "ALL_ACCOUNTS"]["io_input|1|filter_type", "track"]
  # ["io_input|1|track_fields", ""]["input_count", "2"]["output_count", "0"]["splat", []]["captures", ["maps_agent"]]["agent_name", "maps_agent"]
  ## do the save

  # delte cases  (ex:  delete_input|0)
  if params['submit'].include?('delete_')
    id = params['submit'].split('|')[1]
    puts "Delete id #{id}"
    cfg = agent_io_configuration(@agent_name)
    puts "Old io cfg #{cfg}"
    cfg['input_filters'].reject! { |f| f['id'] == id } if params['submit'].include?('input')
    cfg['output_filters'].reject! { |f| f['id'] == id } if params['submit'].include?('output')

    puts "New io cfg #{cfg}"
    set_agent_io_configuration(@agent_name, cfg)
    redirect("/agents/#{@agent_name}/configure")
    return
  end

  # save general
  general_cfg = {
    'track_keep_last_known_values_of_fields' => (params["general_track_keep_last_known_values_of_fields"] != nil),
    'track_injection_filter_already_set_fields_value' => (params["general_track_injection_filter_already_set_fields_value"] != nil)
  }
  set_agent_general_configuration(@agent_name, general_cfg)

  # save io
  io_cfg = {
    'input_filters' => [],
    'output_filters' => []
  }
  input_count = params['input_count'].to_i
  io_cfg['input_filters'] = []
  (0..input_count-1).each do |i|
    # protect the splits
    params["io_input|#{i}|accounts"] = "" if params["io_input|#{i}|accounts"] == nil
    params["io_input|#{i}|msg_channels"] = "" if params["io_input|#{i}|msg_channels"] == nil
    params["io_input|#{i}|track_fields"] = "" if params["io_input|#{i}|track_fields"] == nil
    params["io_input|#{i}|col_names"] = "" if params["io_input|#{i}|col_names"] == nil

    io_cfg['input_filters'] << {
      'id' => params["io_input|#{i}|id"],
      'allowed_accounts' => params["io_input|#{i}|accounts"].split("\r\n"),
      'type' => params["io_input|#{i}|filter_type"],
      'allowed_message_channels' => params["io_input|#{i}|msg_channels"].split("\r\n"),
      'allowed_track_fields' => params["io_input|#{i}|track_fields"].split("\r\n"),
      'allowed_collection_definition_names' => params["io_input|#{i}|col_names"].split("\r\n"),
      'track_hide_location' => (params["io_input|#{i}|hide_location"] != nil),
      'track_hide_time' => (params["io_input|#{i}|hide_time"] != nil),
      'track_fields_cached' => (params["io_input|#{i}|fields_cached"] != nil)
    }
  end
  input_count = params['output_count'].to_i
  io_cfg['output_filters'] = []
  (0..input_count-1).each do |i|

    params["io_output|#{i}|accounts"] = "" if params["io_output|#{i}|accounts"] == nil
    params["io_output|#{i}|msg_channels"] = "" if params["io_output|#{i}|msg_channels"] == nil
    params["io_output|#{i}|track_fields"] = "" if params["io_output|#{i}|track_fields"] == nil
    params["io_output|#{i}|col_names"] = "" if params["io_output|#{i}|col_names"] == nil

    io_cfg['output_filters'] << {
      'id' => params["io_output|#{i}|id"],
      'allowed_accounts' => params["io_output|#{i}|accounts"].split("\r\n"),
      'type' => params["io_output|#{i}|filter_type"],
      'allowed_message_channels' => params["io_output|#{i}|msg_channels"].split("\r\n"),
      'allowed_track_fields' => params["io_output|#{i}|track_fields"].split("\r\n"),
      'allowed_collection_definition_names' => params["io_output|#{i}|col_names"].split("\r\n"),
      'track_hide_location' => (params["io_output|#{i}|hide_location"] != nil),
      'track_hide_time' => (params["io_output|#{i}|hide_time"] != nil)
    }
  end
  set_agent_io_configuration(@agent_name, io_cfg)


  # create if needed

  if params['submit'] == 'save_config_and_create_input'
    io_cfg = agent_io_configuration(@agent_name)
    io_cfg['input_filters'] << {
      'id' => SecureRandom.hex(5),
      'allowed_accounts' => ['ALL_ACCOUNTS'],
      'type' => 'track',
      'allowed_message_channels' => ["com.mdi.services.#{@agent_name}"],
      'allowed_track_fields' => [],
      'allowed_collection_definition_names' => [],
      'track_hide_location' => false,
      'track_hide_time' => false,
      'track_fields_cached' => false
    }
    set_agent_io_configuration(@agent_name, io_cfg)
  end
  if params['submit'] == 'save_config_and_create_output'
    io_cfg = agent_io_configuration(@agent_name)
    io_cfg['output_filters'] << {
      'id' => SecureRandom.hex(5),
      'allowed_accounts' => ['ALL_ACCOUNTS'],
      'type' => 'track',
      'allowed_message_channels' => ["com.mdi.services.#{@agent_name}"],
      'allowed_track_fields' => [],
      'allowed_collection_definition_names' => [],
      'track_hide_location' => false,
      'track_hide_time' => false
    }
    set_agent_io_configuration(@agent_name, io_cfg)
  end

  redirect("/agents/#{@agent_name}/configure")

  # io_hash = {}
  # general_hash = {}

  # set_agent_io_configuration(params[:agent_name], io_hash)
  # set_agent_general_configuration(params[:agent_name], general_hash)

  # redirect('/projects')
  params
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


  # doing it in rush - to cleanup - block the restart, ugly
  # get agents list
  agents_to_run=[]
  blabla = GEN.get_run_agents
  root_path = File.expand_path(File.dirname(__FILE__))
  blabla.each do |agent|
    agents_to_run << File.expand_path(File.join(root_path, '../../cloud_agents', "#{agent}"))
  end
  p "restart server with #{agents_to_run}"


  # launch in a new thread to avoid being stuck here
  Thread.start {
    # stop
    `cd ../local_cloud; ./local_cloud.sh stop`


    # call import agent
    command = "cd ../local_cloud; ./local_cloud.sh import_agents #{agents_to_run.length} #{agents_to_run.join(' ')}"
    p "Call command #{command}"
    `#{command}`

    # start
    `cd ../local_cloud; ./local_cloud.sh start`
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

get '/tests' do
  @active_tab = "unit_tests"
  erb :tests
end

get '/tests/available_agents' do
  get_currently_mounted_agents.to_json
end

post '/tests/start' do
  uri = URI("http://0.0.0.0:5001/tests/start")
  req = Net::HTTP::Post.new(uri.path)
  req.body = request.body.read
  req.content_type = "application/json"
  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end
  if res.code == "200"
    res.body
  else
    halt(500, "<h1>The server responsed:</h1><div>#{res.body}</div>")
  end
end

# No specific body required
post '/tests/stop' do
  uri = URI("http://0.0.0.0:5001/tests/stop")
  req = Net::HTTP::Post.new(uri.path)
  req.body = request.body.read
  req.content_type = "application/json"
  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end
  if res.code == "200"
    res.body
  else
    halt(500, "<h1>The server responsed:</h1><div>#{res.body}</div>")
  end
end

get '/tests/status' do
  uri = URI('http://0.0.0.0:5001/tests/status') # TODO add filter
  Net::HTTP.get(uri)
end

get '/tests/status/text' do
  attachment "tests_results.txt"
  uri = URI('http://0.0.0.0:5001/tests/status/text')
  out = Net::HTTP.get(uri)
  out << "\n\n"
  out << "# Version information\n\n"
  out << "SDK version: #{get_sdk_version}\n"
  out << "VM version: #{current_sdk_vm_base_version}\n"
end

get '/report_issue' do
  path = dump_state()
  flash[:notice] = "Rapport and files dumped to #{path}."
  redirect("/projects")
end
