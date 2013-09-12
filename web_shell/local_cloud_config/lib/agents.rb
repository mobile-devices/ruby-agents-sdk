
#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


class Agent < Struct.new(:name, :running, :agent_stats, :cron_tasks)
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
  puts "add_new_agent #{agent_name}"
  if agent_name.empty?
    puts "Agent name can not be empty."
    flash[:popup_error] = "Agent name can not be empty."
  elsif create_new_agent(agent_name)
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
    params = {}
    jstats = http_get("http://localhost:5001/sdk_stats")
    puts "update_sdk_stats downloaded: \n #{jstats}"
    stats = JSON.parse(jstats)

    $sdk_server_stats = stats['server']
    puts "sdk_server_stats: \n #{$sdk_server_stats}"

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
  $sdk_server_stats ||= {}
end


def update_cron_tasks
  puts "update_cron_tasks try ..."
  begin
    jcron = http_get("http://localhost:5001/get_cron_tasks")
    puts "update_cron_tasks downloaded: \n #{jcron}"
    cron = JSON.parse(jcron)

    # agents
    cron.each { |k,v|
      if agents[k] != nil
        puts "##### #{v}"
        v.each { |e|
          agents[k].cron_tasks << JSON.parse(e)
        }
      end
    }

  rescue Exception => e
    stack=""
    e.backtrace.take(20).each { |trace|
      stack+="  >> #{trace}\n"
    }
    puts "update_cron_tasks ERROR: #{e.inspect}\n\n#{stack}"
  end

  p ''
end

# Export all data related to the given agent in a .tar.gz placed in the sdk_logs folder
# Warning: string manipulation in this method is done without any concern for performance
def export(agent_name)
  # copy everything in a folder in logs
  time = Time.now
  random = Random.rand(1000) # quick-and-dirty way to ensure uniqueness of the file if several requests are simultaneously treated
  file_name = time.utc.strftime("%Y_%m_%d_%H%M%Sutc_#{agent_name}_dump_#{random}")
  save_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "logs", file_name))
  FileUtils.mkdir_p(save_path)
  agent_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "..", "ruby_workspace", agent_name))
  log_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "logs"))

  # copy source (but ignore .svn, .git)
  target = File.join(save_path, "src")
  source = agent_path
  FileUtils.mkdir_p(target)
  Dir.glob("#{source}/**/*").reject{|f| f['.svn'] || f['.git']}.each do |oldfile|
    newfile = target + oldfile.sub(source, '')
    File.file?(oldfile) ? FileUtils.copy(oldfile, newfile) : FileUtils.mkdir(newfile)
  end

  # copy versions
  File.open(File.join(save_path, "info"), 'w') do |file|
    file.write("Dumped on #{time.to_s}\n")
    file.write("Agent: #{agent_name} \n")
    file.write("VM version: #{current_sdk_vm_base_version}\n")
    file.write("SDK version: #{get_sdk_version}\n")
  end

  # copy logs
  # As these logs can become pretty big during long sessions, (several 10 * Mbytes) we limit their size before copying
  # limit to 30 000 lines
  FileUtils.mkdir_p(File.join(save_path, "logs"))
  %w(daemon_server_config.log daemon_server.log ruby-agent-sdk-server.log).each do |log_file|
    File.open(File.join(log_path, log_file)) do |file|
      # if performance becomes an issue, use IO#seek instead
      lines = file.readlines
      if(lines.size) > 30000
        lines = lines[-30000..-1]
      end
      File.open(File.join(save_path, "logs", log_file), 'w') {|file| file.write(lines.join("\n"))}
    end
  end

  # tar the results
  `cd #{save_path}/.. && tar -czf #{save_path}.tar.gz #{file_name}`
  FileUtils.rm_rf(save_path)
  return "sdk_logs/#{file_name}.tar.gz"
end
