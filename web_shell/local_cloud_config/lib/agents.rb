#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


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
  puts "add_new_agent #{agent_name}"
  if create_new_agent(agent_name)
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