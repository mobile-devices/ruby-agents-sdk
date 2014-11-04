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

def logs_server_file_content
  return File.read(log_server_path) if File.exist?(log_server_path)
  nil
end


def logs_server
  logs = logs_server_file_content
  return [] if logs == nil
  log_server = []
  logs.each_line { |line|
    line.delete!("\n")
    log_server << line
  }
  log_server
end

def logs_agent_file_content
  return File.read(log_agents_path) if File.exist?(log_agents_path)
  nil
end


def logs_agent
  logs = logs_agent_file_content
  retirn [] if logs == nil
  logs = File.read(log_agents_path)
  log_server = []
  logs.each_line { |line|
    line.delete!("\n")
    logs_agent << line
  }
  logs_agent
end

def logs_agent_punked
  if File.exist?(log_agents_path)
    logs = File.read(log_agents_path)
    PUNK.un_punk(logs)
  else
    []
  end
end
