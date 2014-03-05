#!/usr/bin/ruby -w

###################################################################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
###################################################################################################


# server run id
if File.exists?('/tmp/should_mdi_server_run_id')
  should_id = File.read('/tmp/should_mdi_server_run_id')
else
  should_id = "??"
end
File.open('/tmp/mdi_server_run_id', 'w') { |file| file.write(should_id) }

require 'sinatra'
set :bind, '0.0.0.0'
set :port, '5001'
require 'json'
require 'base64'
require 'rspec'

require_relative 'tests_utils/test_runner'

$local_cloud_start_time = Time.now
$main_server_root_path = File.expand_path("..", __FILE__)


# sdk jBinaryGate message queue to device
$message_to_device = []
$mutex_message_to_device = Mutex.new

# cloud
require_relative 'fake_cloud_lib/cloud_connect_sdk_module'

# ragent
require_relative 'ragent_bay/ragent'
RAGENT.init('sdk-vm')

# reset stats
SDK_STATS.reset_stats
RUBY_AGENT_STATS.init('sdk_ragent', 'ruby agent', '777', '007', {})




PUNK.end('sys','ok','','SERVER ready to work - click for details')


###################################################################################################

def get_json_from_request(request)
  to_parse = ""
  begin
    request.body.rewind  # in case someone already read it
    to_parse = request.body.read
    JSON.parse(to_parse)
  rescue Exception => e
    CC.logger.error("Server: error while reading json (len=#{to_parse.length}) \n #{to_parse}")
    RAGENT.api.mdi.tools.print_ruby_exception(e)
    nil
  end
end

def welcome_new_data_from_outside(index_type, request)
  case index_type
  when 0
    kind_str = 'presence'
    kind_tok = 'PRESENCE'
  when 1
    kind_str = 'message'
    kind_tok = 'MESSAGE'
  when 2
    kind_str = 'track'
    kind_tok = 'TRACK'
  when 3
    kind_str = 'order'
    kind_tok = 'ORDER'
  end

  PUNK.start('a','receiving something ...')
  SDK_STATS.stats['server']['received'][index_type] += 1
  SDK_STATS.stats['server']['total_received'] += 1
  jsonData = get_json_from_request(request)
  if jsonData == nil
    response.body = 'error while parsing json'
    SDK_STATS.stats['server']['err_parse'][index_type] += 1
    SDK_STATS.stats['server']['total_error'] += 1
    PUNK.end('a','ko','in',"SERVER <- #{kind_tok} : parse json fail")
    nil
  end
  PUNK.drop('a')
  jsonData
end

def push_something_to_device(something)
  CC.logger.debug("Server: push_something_to_device:\n#{something}")

  # send the message to the tests helper to enable using it in testing utilities (without base64 encoding!)
  # TestsHelper.push_to_test_gate(something)


  # in fake mode, the content or a message must be base64 encode
  if something['payload']['type'] == 'message'
    something['payload']['payload'] = Base64.encode64(something['payload']['payload'])
  end

  $mutex_message_to_device.synchronize do
    $message_to_device << something
    SDK_STATS.stats['server']['in_queue'] = $message_to_device.size
  end
  SDK_STATS.stats['server']['total_queued'] += 1
  SDK_STATS.stats['server']['total_sent'] += 1
end

#test: curl localhost:5001/dynamic_channel_request
get '/dynamic_channel_request' do
  msg = RAGENT.api.mdi.dialog.create_new_message
  msg.channel = 0
  msg.content = RAGENT.map_supported_message_channels.to_json
  msg.type = 'dynchannelsmessage'
  msg.content = Base64.encode64(msg.content) # Base64 it
  CC.logger.debug("Server: /dynamic_channel_request has #{RAGENT.supported_message_channels.count} channels :\n#{msg.to_hash.to_json}")
  msg.to_hash.to_json
end


#test: curl -i localhost:5001/new_message_from_cloud
get '/new_message_from_cloud' do
  tmp_hash = Hash.new
  $mutex_message_to_device.synchronize do
    tmp_hash = $message_to_device.clone
    $message_to_device.clear
  end
  CC.logger.debug("Server: /new_message_from_cloud has #{tmp_hash.count} messages :\n#{tmp_hash.to_json}")
  tmp_hash.to_json
end

#test : curl http://localhost:5001/sdk_stats
get '/sdk_stats' do
  SDK_STATS.stats['server']['uptime'] = (Time.now - $local_cloud_start_time).round
  SDK_STATS.stats.to_json
end

#test : curl http://localhost:5001/get_cron_tasks
get '/get_cron_tasks' do
  RAGENT.cron_tasks_to_map.to_json
end

#test:
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"connect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"reconnect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"disconnect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
post '/presence' do
  hashData = welcome_new_data_from_outside(0, request)
  response.body = '{}'
  return if hashData == nil
  RIM.handle_presence(hashData)
  response.status = 200 # everything went perfeclty fine .. don't ask .. no don't look ... you should believe me
end

#test:
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.psa.messagingagent.echo.0", "recorded_at":78364, "payload":"/test/echo/for/me?da=ble", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.services.agps_agent", "recorded_at":78364, "payload":"check/aaaaaaaaaabbbbbbbbbbcccccccccc12", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.services.ragent_basic_tests_agent", "recorded_at":78364, "payload":"L3Rlc3QvZWNoby9mb3IvbWU/ZGE9Ymxl", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message

#test with content base64 encoded :
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.psa.messagingagent.echo.0", "recorded_at":78364, "payload":"L3Rlc3QvZWNoby9mb3IvbWU/ZGE9Ymxl", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.services.agps_agent", "recorded_at":78364, "payload":"Y2hlY2svYWFhYWFhYWFhYWJiYmJiYmJiYmJjY2NjY2NjY2NjMTI=", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message
#protogen: curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d $'{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.services.protogen_fun_agent", "recorded_at":78364, "payload":"gqR0eXBlAaNtc2eCpG5hbWWvbXlsaXR0bGVyZXF1ZXN0p2xhdGxpc3STAQID", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message
#protogen: curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d $'{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.services.ragent_basic_tests_agent", "recorded_at":78364, "payload":"g6F2rTEtMS15KzUvNHVRT0WkdHlwZQCjbXNng6hwb2lfbmFtZaVzYXVuYaJf\nc8CiX2jA\n", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message



post '/message' do
  hashData = welcome_new_data_from_outside(1, request)
  response.body = '{}'
  return if hashData == nil
  RIM.handle_message(hashData)
  nil
end

#test:
# curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"default"}, "payload":{"sender":"351777047016827", "id":19, "reset":true, "128":"roblochon", "recorded_at":1368449272, "asset":"351777047016827"}}' http://localhost:5001/track
post '/track' do
  hashData = welcome_new_data_from_outside(2, request)
  response.body = '{}'
  return if hashData == nil
  RIM.handle_track(hashData)
  nil
end

#test:
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"agent":"agps_agent", "order":"refresh_agps_files"}' http://localhost:5001/remote_call
post '/remote_call' do
  hashData = welcome_new_data_from_outside(3, request)
  response.body = '{}'
  return if hashData == nil
  RIM.handle_order(hashData)
  nil
end

# todo: refactor, method too long
# get '/start_tests' do
#   unless params.has_key?("agents")
#     halt(400, "'agents' parameter is mandatory")
#   end
#   agents_array = params['agents']
#   unless agents_array.size >= 1
#     halt(400, "'agents' parameters must include at least one agent")
#   end
#   CC.logger.info("Starting tests for agents " + agents_array.inspect)
#   TestsRunner.instance.start_tests(agents_array)
#   "Tests started for agents " + agents_array.inspect
# end

# POST /tests/start
# Content-Type: application/json
# {
# "agents": ["name_a", "name_b"]...  
# }
post '/tests/start' do
  data = JSON.parse(request.body.read)
  unless data.include?("agents") && data["agents"].is_a?(Array)
    halt(400, 'You must provide a list of agents')
  end
  hash = data["agents"].each_with_object({}) do |agent_name, hash|
    hash[agent_name] = File.join(File.dirname(__FILE__), "ragent_bay", "agents_project_source", agent_name, "tests")
  end  
  Tests::TestsRunner.instance.start_tests(hash)
  {'status' => 'tests started'}.to_json
end

# get '/stop_tests' do
#   TestsRunner.instance.stop_tests
#   "Tests stopped"
# end

# No specific body required
post '/tests/stop' do
  Tests::TestsRunner.instance.stop_tests
  {'status' => 'tests stopped'}.to_json
end

# GET /test/status?filter[]=agent_name&filter[]=index
# filter is an array, each pair in it is the couple (agent_name, min_index)
# min_index is the minimum index example to include in the results
# note that if the status is anything other than "started", then the filter parameter is ignored for the geiven agent 
get '/tests/status' do
  if(params[:filter])
    Tests::TestsRunner.instance.get_status(Hash[params[:filter]]).to_json
  else
    Tests::TestsRunner.instance.get_status.to_json
  end
end

#test : curl http://localhost:5001/is_alive
get '/is_alive' do
  "I'm alive!"
end
