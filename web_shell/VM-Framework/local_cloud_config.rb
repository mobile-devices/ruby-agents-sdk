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
require 'json'

#=========================================================================================
require 'net/http'

def http_get(address)

  url = URI.parse(address)
  req = Net::HTTP::Get.new(url.path)
  res = Net::HTTP.start(url.host, url.port) {|http|
    http.request(req)
  }
  res.body

end

#=========================================================================================
class Agent < Struct.new(:name, :running, :agent_stats)
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
    run_agents = get_run_agents
    get_available_agents.inject({}) do |agents, agent_name|
      agents[agent_name] = Agent.new(agent_name, run_agents.include?(agent_name), {})
      agents
    end
  end
end


def update_sdk_stats
  puts "update_sdk_stats try ..."
  begin
    # server stats
    params = {}
    jstats =  http_get("http://localhost:5001/sdk_stats")
    puts "update_sdk_stats downloaded: \n #{jstats}"
    stats = JSON.parse(jstats)

    @sdk_server_stats = stats['server']
    puts "sdk_server_stats: \n #{@sdk_server_stats}"

    # agents
    agents_stats =  stats['agents']
    agents_stats.each { |k,v|
      puts "for agent #{k} we set #{v}"
      agents[k].agent_stats = v
    }

    puts "Agent with stats: \n #{agents}"
  rescue Exception => e
    stack=""
    e.backtrace.take(20).each { |trace|
      stack+="  >> #{trace}\n"
    }
    puts "update_sdk_stats ERROR: #{e.inspect}\n\n#{stack}"
  end
  #todo: in case of agent not updated, set as default_agent found in server

end

def sdk_stats
  @sdk_server_stats ||= {}
end

#=========================================================================================

def gen_md_from_file(folder_path, files)
  doc = ""
  accepted_formats = [".md"]
  files.each { |file|
    next if !(accepted_formats.include? File.extname(file))
    file_title = file.clone
    file_title.gsub!('.md','')
    file_title.gsub!('_',' ')
    doc += "\n\n# #{file_title}\n"
    doc += File.read("#{folder_path}#{file}")
    doc += '<hr/><hr/>'
  }
  # replace version in doc
  doc.gsub!('XXXX_VERSION',"#{get_sdk_version}")
  doc
end

def sdk_doc_md
  $sdk_documentation ||= begin
    files = get_files('../../docs/to_user/')
    doc_beginner = []
    doc_code_ex = []
    doc_others = []
    files.each { |file|
      if file.include?('Beginner::')
        doc_beginner << file
        next
      end
      if file.include?('Code Example::')
        doc_code_ex << file
        next
      end
      doc_others << file
    }

    files = []
    # first 'Beginner::'
    files += doc_beginner.sort
    # else other
    files += doc_others.sort
    # end 'Code Example::'
    files += doc_code_ex.sort

    gen_md_from_file('../../docs/to_user/', files)
  end
end

def sdk_patch_note_md
  $sdk_patch_note ||= begin
    files = get_files('../../docs/patch_note/')
    # reverse sort
    files = files.sort.reverse
    gen_md_from_file('../../docs/patch_note/', files)
  end
end

def render_documentation(content)
  @html_render = ''
  @toc_render = ''
  return if content == nil

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

  @html_render = markdown.render(content)
  @toc_render =  doc_render.render_menu
end

#=========================================================================================

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

def log_server_path
  @daemon_server_path ||= '../../logs/daemon_server.log'
end

def log_agents_path
  @daemon_ruby_agent_sdk_server_path ||= '../../logs/ruby-agent-sdk-server.log'
end

def logs_server
  if File.exist?(log_server_path)
    logs = File.read(log_server_path)
    logs = Rack::Utils.escape_html(logs)
    logs.gsub!("\n","<br/>")
  else
    ""
  end
end

def logs_agent
  if File.exist?(log_agents_path)
    logs = File.read(log_agents_path)
    logs = Rack::Utils.escape_html(logs)
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
  @action_popup = check_version_change_to_user
  agents_altered
  @agents = agents
  p "getting stats"
  #stats
  update_sdk_stats
  p "stats done"

  erb :projects
end

get '/doc' do
  render_documentation(sdk_doc_md)
  erb :doc
end

get '/patch_note' do
  render_documentation(sdk_patch_note_md)
  erb :patch_note
end

get '/logSdk' do
  erb :logSdk
end

get '/logSdkAgents' do
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
  `./local_cloud.sh restart`
  redirect('/projects')
end


#=========================================================================================