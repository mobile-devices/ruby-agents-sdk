#cloud_server_config.rb

#sinatra pour conf ton sdk
# (run mdi_cloud) agent mgt
# conf dyn channel per agent

require 'sinatra'
set :bind, '0.0.0.0'
set :port, '5000'
require_relative '../scripts/agents_mgt'


#=========================================================================================
class Agent < Struct.new(:name, :running)
end

def agents_altered()
  $agents = nil # invalidate the list
end

def stop_agent(agent)
  remove_agent_from_run_list(agent.name)
  agents_altered
end

def start_agent(agent)
  add_agent_to_run_list(agent.name)
  agents_altered
end

def add_new_agent(agent_name)
  p "add_new_agent #{agent_name}"
  if create_new_agent(agent_name)
    agents_altered
  else
   'error while creating agent'
  end
end

def agents
  $agents ||= begin
    get_available_agents.inject({}) do |agents, agent_name|
      agents[agent_name] = Agent.new(agent_name, get_run_agents.include?(agent_name))
      agents
    end
  end
end

#=========================================================================================
get '/' do
  agents_altered
  @agents = agents
  erb :home
end

post '/agents/:agent_name/start' do
  agent = agents.fetch(params[:agent_name])
  start_agent(agent)
  redirect('/')
end

post '/agents/:agent_name/stop' do
  agent = agents.fetch(params[:agent_name])
  stop_agent(agent)
  redirect('/')
end

post '/create_agents' do
  add_new_agent(params[:agent][:name])
  redirect('/')
end

get '/restart_server' do
  `./local_cloud.sh restart`
  redirect('/')
end


#=========================================================================================