
#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


class Agent < Struct.new(:name, :running, :agent_stats, :cron_tasks)
end

def agents_altered
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

def add_new_agent(agent_name, package_name = nil)
  puts "add_new_agent #{agent_name}"
  if agent_name.empty?
    puts "Agent name can not be empty."
    flash[:popup_error] = "Agent name can not be empty."
  elsif create_new_agent(agent_name, package_name)
    agents_altered
    puts "Agent #{agent_name} successfully created."
  else
    puts "Agent #{agent_name} already exists."
    flash[:popup_error] = "Agent #{agent_name} already exists."
  end
end


def agents
  $sdk_list_of_agents ||= begin
    run_agents = GEN.get_run_agents
    GEN.get_available_agents.inject({}) do |agents, agent_name|
      agents[agent_name] = Agent.new(agent_name, run_agents.include?(agent_name), {}, [])
      agents
    end
  end
end


def update_sdk_stats
  puts "update_sdk_stats try ..."
  begin
    # server stats
    jstats = http_get("http://localhost:5001/sdk_stats")
    #puts "update_sdk_stats downloaded: \n #{jstats}"
    stats = JSON.parse(jstats)

    $sdk_server_stats_full = stats

    $sdk_server_stats = stats['server']
    #puts "sdk_server_stats: \n #{$sdk_server_stats}"

    # agents
    agents_stats =  stats['agents']
    agents_stats.each { |k,v|
      puts "for agent #{k} we set #{v}"
      agents[k].agent_stats = v
    }

    #puts "Agent with stats: \n #{agents}"
  rescue Exception => e
    stack=""
    e.backtrace.take(20).each do |trace|
      stack+="  >> #{trace}\n"
    end
    puts "update_sdk_stats ERROR: #{e.inspect}\n\n#{stack}"
  end
  #todo: in case of agent not updated, set as default_agent found in server

end

def sdk_stats
  $sdk_server_stats ||= {}
end

def sdk_stats_full
  $sdk_server_stats_full ||= {}
end


def update_cron_tasks
  puts "update_cron_tasks try ..."
  begin
    jcron = http_get("http://localhost:5001/get_cron_tasks")
    puts "update_cron_tasks downloaded: \n #{jcron}"
    cron = JSON.parse(jcron)

    # agents
    cron.each do |k,v|
      if agents[k] != nil
        puts "##### #{v}"
        v.each do |e|
          task_info = JSON.parse(e)
          puts "  ######1 #{task_info} "
          task_order = JSON.parse(task_info['order'])
          puts "  ######2 #{task_order} #{task_order['order']}"
          agents[k].cron_tasks << task_order
        end
      end
    end

  rescue Exception => e
    stack=""
    e.backtrace.take(20).each do |trace|
      stack+="  >> #{trace}\n"
    end
    puts "update_cron_tasks ERROR: #{e.inspect}\n\n#{stack}"
  end

  p ''
end

# Export all data related to all agents with "active" set to true to project page
def dump_state()
  # copy everything in a folder in logs
  # todo: copy only relevant agents
  agents_to_save = GEN.get_run_agents
  time = Time.now
  random = Random.rand(1000) # quick-and-dirty way to ensure uniqueness of the file if several requests are simultaneously treated in the same second
  folder_name = time.utc.strftime("%Y_%m_%d_%H%M%Sutc_sdk_dump_#{random}")
  log_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "logs"))
  save_path = File.expand_path(File.join(log_path, folder_name))
  FileUtils.mkdir_p(save_path)
  FileUtils.mkdir_p(File.join(save_path, "src"))
  rapport = []
  rapport << "Dumped on #{time.to_s}"
  rapport << "VM version: #{current_sdk_vm_base_version}"
  rapport << "SDK version: #{get_sdk_version}"
  rapport << ""
  agents_to_save.each do |agent_name|
    agent_path = "#{GEN.workspace_path}/#{agent_name}"
    unless File.directory?(agent_path)
      rapport << "Agent #{agent_name} folder not found at #{agent_path}, skipping this agent"
      next
    end
    # copy source (but ignore .svn, .git, .hg)
    target = File.join(save_path, "src", agent_name)
    source = agent_path
    FileUtils.mkdir_p(target)
    Dir.glob("#{source}/**/*").reject{|f| f['.svn'] || f['.git'] || f['.hg']}.each do |oldfile|
      newfile = target + oldfile.sub(source, '')
      File.file?(oldfile) ? FileUtils.copy(oldfile, newfile) : FileUtils.mkdir(newfile)
    end
    rapport << "Agent #{agent_name} included"
  end

  # copy logs
  # As these logs can become pretty big during long sessions, (several 10 * Mbytes) we limit their size before copying
  FileUtils.mkdir_p(File.join(save_path, "logs"))
  %w(daemon_server_config.log daemon_server.log ruby-agent-sdk-server.log).each do |log_file|
    File.open(File.join(save_path, "logs", log_file), 'w') {|file| file.write(`cd #{log_path} && tail -n 10000 #{log_file}`)}
  end

  # add rapport
  rapport << ""
  rapport << "Export finished"
  File.open(File.join(save_path, "info"), 'w') {|file| file.write(rapport.join("\n"))}

  # tar the results
  `cd #{save_path}/.. && tar -czf #{save_path}.tar.gz #{folder_name}`
  FileUtils.rm_rf(save_path)
  "sdk_logs/#{folder_name}.tar.gz"
end

def make_package_agent(agent)
  agent_path = "#{GEN.workspace_path}/#{agent.name}"
  date = Time.now.utc.strftime("%Y_%m_%d_%H%M%S")
  random = Random.rand(1000)
  package_name = "PKG_Agent_Ruby_4RAgent_#{agent.name}_#{date}_#{random}.tar.gz"
  FileUtils.mkdir_p(GEN.package_output_path)

  command = "tar -czf #{GEN.package_output_path}/#{package_name} #{agent_path}"
  p "running command #{command}"

  # make the package (todo test if error)
  `#{command}`

  "output/#{package_name}"
end

# @return [Array<String>] the list of the currently mounted agents (note that agent.running returns true if the
#                         agent is scheduled to be mounted at next reboot even if it is not currently mounted)
# @todo design a robust API to handle this kind of needs, rather than using ad-hoc methods.
def get_currently_mounted_agents
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "local_cloud", "ragent_bay", "agents_project_source", "*"))
  agents_path = Dir.glob(path).select {|f| File.directory? f}
  agents_path.map{|a| a.split(File::SEPARATOR).last}
end
