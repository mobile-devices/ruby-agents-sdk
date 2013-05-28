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

require_relative '../agents_generator/agents_mgt'
include GEN

require 'sinatra'
set :bind, '0.0.0.0'
set :port, '5000'

require 'rack/flash'
enable :sessions
use Rack::Flash

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
  # popup error
  @error_popup_msg = flash[:popup_error]

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

  `cd ../local_cloud; ./local_cloud.sh restart`
  redirect('/projects')
end
