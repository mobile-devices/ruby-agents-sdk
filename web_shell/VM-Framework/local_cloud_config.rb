#cloud_server_config.rb

#sinatra pour conf ton sdk
# (run mdi_cloud) agent mgt
# conf dyn channel per agent

require 'redcarpet'
require_relative 'lib/readcarpet_overload'

require 'sinatra'
set :bind, '0.0.0.0'
set :port, '5000'
require_relative '../scripts/agents_mgt'

#=========================================================================================
class Agent < Struct.new(:name, :running)
end

def agents_altered()
  $sdk_list_of_agents = nil # invalidate the list
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
  $sdk_list_of_agents ||= begin
    get_available_agents.inject({}) do |agents, agent_name|
      agents[agent_name] = Agent.new(agent_name, get_run_agents.include?(agent_name))
      agents
    end
  end
end

def sdk_doc_md
  $sdk_documentation ||= begin
    files = get_files('../../docs/to_user/')
    accepted_formats = [".md"]
    doc = ""
    files.each { |file|
      next if !(accepted_formats.include? File.extname(file))
      file_title = file.clone
      file_title.gsub!('.md','')
      file_title.gsub!('_',' ')
      doc += "\n\n# #{file_title}\n"
      doc += File.read("../../docs/to_user/#{file}")
      doc += '<hr/><hr/>'
    }
    # replace version in doc
    doc.gsub!('XXXX_VERSION',"#{get_sdk_version}")
  end
end

def log_server_path
  @daemon_server_path ||= '../../logs/daemon_server.log'
end

def log_agents_path
  @daemon_ruby_agent_sdk_server_path ||= '../../logs/ruby-agent-sdk-server.log'
end


def logs_server
  if File.exist?(log_server_path)
    logs = File.read(log_server_path)
    logs.gsub!("\n","<br/>")
  else
    ""
  end
end

def logs_agent
  if File.exist?(log_agents_path)
    logs = File.read(log_agents_path)
    logs.gsub!("\n","<br/>")
  else
    ""
  end
end

#=========================================================================================
get '/' do
  redirect('/projects')
end

get '/projects' do
  agents_altered
  @agents = agents
  erb :projects
end

get '/doc' do
  doc_render = Redcarpet::Render::ColorHTML.new(:with_toc_data => true, :filter_html  => false, :hard_wrap => true)
  markdown = Redcarpet::Markdown.new(doc_render,
                                          no_intra_emphasis: false,
                                          tables: true,
                                          fenced_code_blocks: true,
                                          autolink: true,
                                          strikethrough: true,
                                          lax_html_blocks: true,
                                          space_after_headers: true,
                                          superscript: true)

  @html_render = markdown.render(sdk_doc_md)
  @toc_render =  doc_render.render_menu
  erb :doc
end

get '/logSdk' do
  erb :logSdk
end

get '/logSdkAgents' do
  erb :logSdkAgents
end

get '/reset_daemon_server_log' do
  File.delete(log_server_path)
  redirect('/logSdk')
end

get '/reset_ruby_agent_sdk_server_log' do
  File.delete(log_agents_path)
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
  `./local_cloud.sh restart`
  redirect('/projects')
end


#=========================================================================================