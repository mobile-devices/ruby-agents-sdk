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


def is_reset_log_checked
  @reset_log_checked ||= begin
    if File.exist?('.reset_log_checked')
      File.read('.reset_log_checked')
    else
      set_reset_log_checked(true)
      true
    end
  end
end

def set_reset_log_checked(val)
  if (@previous_reset_log_checked != val)
    File.open('.reset_log_checked', 'w') { |file| file.write(val) }
    @previous_reset_log_checked = val
    @reset_log_checked = val
  end
end
