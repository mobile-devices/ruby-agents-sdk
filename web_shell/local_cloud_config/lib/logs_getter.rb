#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

def log_server_path
  @daemon_server_path ||= '../../logs/daemon_server.log'
end

def log_agents_path
  @daemon_ruby_agent_sdk_server_path ||= '../../logs/ruby-agent-sdk-server.log'
end

def logs_server
  if File.exist?(log_server_path)
    logs = File.read(log_server_path)
    log_server = []
    logs.each_line { |line|
      line.delete!("\n")
      log_server << line
    }
    log_server
  else
    []
  end
end

def logs_agent
  if File.exist?(log_agents_path)
    logs = File.read(log_agents_path)
    logs.each_line { |line|
      line.delete!("\n")
      logs_agent << line
    }
    logs_agent
  else
    []
  end
end

def logs_agent_punked
  if File.exist?(log_agents_path)
    logs = File.read(log_agents_path)
    PUNK.un_punk(logs)
  else
    []
  end
end
