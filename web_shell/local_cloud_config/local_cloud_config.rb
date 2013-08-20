#!/usr/bin/ruby -w

#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'json'

require 'redcarpet'
require_relative 'lib/readcarpet_overload'
require_relative 'lib/agents'
require_relative 'lib/documentation'
require_relative 'lib/logs_getter'
require_relative 'lib/net_http'
require_relative 'lib/erb_config'

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

#=========================================================================================
get '/' do
 redirect('/projects')
end

get '/projects' do
  @active_tab='projects'

  @action_popup = check_version_change_to_user
  agents_altered
  @agents = agents
  # stats
  update_sdk_stats
  # cron
  update_cron_tasks
  # popup error
  @error_popup_msg = flash[:popup_error]


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

  `cd ../local_cloud; ./local_cloud.sh restart`


  p "redirecting to #{params['redirect_to']}"
  if params['redirect_to']
    redirect(params['redirect_to'])
  else
    redirect('/projects')
  end

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