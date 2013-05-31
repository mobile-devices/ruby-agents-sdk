
job_type :execute_order, 'curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d \'{"agent":"agps_agent", "order":":task", "params":":params"}\' http://localhost:5001/remote_call'
# Here you define your rules to schedule order to be sent to your agent

# Example:

# every 2.hours do
#   execute_order "66"
# end

# every 1.day, :at => '4:30 am' do
#   execute_order "refresh", :params => "parameters"
# end

# You MUST use the command 'execute_order'

# Learn more about whenever: http://github.com/javan/whenever


every 5.minutes do
  execute_order "refresh_agps_files", :params => "parameters"
end


every 1.hours do
  execute_order "do nothing", :params => "parameters"
end


