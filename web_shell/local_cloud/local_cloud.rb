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

$local_cloud_start_time = Time.now

require 'sinatra'
set :bind, '0.0.0.0'
set :port, '5001'
require 'json'
require 'base64'
require 'rspec'

$main_server_root_path = File.expand_path("..", __FILE__)

$allow_non_protogen = true
$ENV_TARGET = 'sdk-vm'

$tester_thread = Thread.new {}

## FAKE CLOUD LIB #################################################################################

require 'active_support/all'

require_relative 'fake_cloud_lib/cloud_connect_sdk_module'
require_relative 'fake_cloud_lib/cloud_gate'
require_relative 'fake_cloud_lib/punkabe'
require_relative 'fake_cloud_lib/ragent_helper'

## API ############################################################################################

require_relative 'API/sdk_stats'
require_relative 'API/cloud_connect_services'
require_relative 'API/cloud_connect_services_internal'

# tests
require_relative 'tests_utils/tests_runner'

#### Agent generation #############################################################################
require_relative '../agents_generator/agents_mgt'
include GEN

CC.logger.info("\n\n\n\n\n")

CC.logger.info("#{$main_server_root_path}/../agents_generator/cloud_agents_generated/running_agents")

# clear output
if File.exists?("../agents_generator/cloud_agents_generated")
  FileUtils.rm_r("../agents_generator/cloud_agents_generated")
end
FileUtils.mkdir_p("#{source_path}/cloud_agents_generated")

# agent running to generation path
File.open("#{$main_server_root_path}/../agents_generator/cloud_agents_generated/running_agents", 'w') { |file| file.write(get_run_agents().join('|')) }

# gen

#progen generation
GEN.generate_agents_protogen
CC.logger.info("Protogen generation finished.")


# main code generation
PUNK.start('a')
begin
  rapport = GEN.generate_agents
  CC.logger.debug(rapport)
  CC.logger.info("agents generation successful")
  PUNK.end('a','ok','','SERVER generated agents')
rescue Exception => e
  CC.logger.debug("agents generation failed")
  CCS.print_ruby_exception(e)
  PUNK.end('a','ko','','SERVER generation agents fail')
  raise e
end

## Generate cron tasks ############################################################################

PUNK.start('a')
begin
  crons = GEN.generated_get_agents_whenever_content
  FileUtils.mkdir_p("#{$main_server_root_path}/config")
  File.open("#{$main_server_root_path}/config/schedule.rb", 'w') { |file| file.write(crons) }
  $agents_cron_tasks = GEN.get_agents_cron_tasks(RH.running_agents)
  CC.logger.debug("agents_cron_tasks =\n#{$agents_cron_tasks}")
  PUNK.end('a','ok','','SERVER created cron tasks')
rescue Exception => e
  PUNK.end('a','ko','','SERVER cron tasks creation fail')
  raise e
end

#### Init server ##################################################################################

# include generated code
require_relative '../agents_generator/cloud_agents_generated/generated'

# dynamic channel
$dyn_channels = GEN.generated_get_dyn_channel

# message queue to device
$message_to_device = []
$mutex_message_to_device = Mutex.new()

# reset starts
SDK_STATS.reset_stats

#todo use CCSI.user_class_subscriber lists to print below
RH.running_agents.each { |agent|
  PUNK.start('a')
  PUNK.end('a','system','',"SERVER mounts AGENT:#{agent}TNEGA")

  # verify some configuration
  PUNK.start('a')
  sub_p = get_agent_is_sub_presence(agent)
  if sub_p == true
    PUNK.end('a','system','',"AGENT:#{agent}TNEGA subscribe presence")
  end

  PUNK.start('a')
  sub_m = get_agent_is_sub_message(agent)
  if sub_m == true
    PUNK.end('a','system','',"AGENT:#{agent}TNEGA subscribe message")
  end

  PUNK.start('a')
  sub_t = get_agent_is_sub_track(agent)
  if sub_t == true
    PUNK.end('a','system','',"AGENT:#{agent}TNEGA subscribe track")
  end

  PUNK.drop('a')
}

agents_list_str=""
RH.running_agents.each { |agent|
  agents_list_str+="|   . #{agent}\n"
}
CC.logger.info("\n\n+===========================================================\n| starting ruby-agent-sdk-server with #{get_run_agents().count} agents:\n#{agents_list_str}+===========================================================\n")


CC.logger.info("ruby-agent-sdk-server ready to use !\n\n")

PUNK.end('sys','ok','','SERVER ready to use !')

###################################################################################################

def get_json_from_request(request)
  to_parse = ""
  begin
    request.body.rewind  # in case someone already read it
    to_parse = request.body.read
    JSON.parse(to_parse)
  rescue Exception => e
    CC.logger.error("Server: error while reading json (len=#{to_parse.length}) \n #{to_parse}")
    CCS.print_ruby_exception(e)
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
    return
  end
  CC.logger.debug("\n\n\n\nServer: new incomming #{kind_str}:\n#{jsonData}")
  jsonData
end

def crop_ref(ref, size)
  ref_str = "#{ref}"
  if ref_str.size <= size
    ref_str
  else
    ref_str.split(//).last(size).join('')
  end
end

#test: curl localhost:5001/dynamic_channel_request
get '/dynamic_channel_request' do

  msg = CCS::Message.new()
  msg.channel = 0
  msg.content = $dyn_channels.clone.to_json
  msg.type = 'dynchannelsmessage'

  # Base64 it
  msg.content = Base64.encode64(msg.content)

  CC.logger.debug("Server: /dynamic_channel_request has #{$dyn_channels.count} channels :\n#{msg.to_hash.to_json}")
  msg.to_hash.to_json
end


#test: curl -i localhost:5001/new_message_from_cloud
get '/new_message_from_cloud' do
  tmp_hash = Hash.new()
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
  $agents_cron_tasks.to_json
end


#test:
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"connect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"reconnect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"disconnect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
post '/presence' do
  hashData = welcome_new_data_from_outside(0, request)
  handle_msg_from_device('presence', hashData)
  response.body = '{}'
end

#test:
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.psa.messagingagent.echo.0", "recorded_at":78364, "payload":"/test/echo/for/me?da=ble", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.services.agps_agent", "recorded_at":78364, "payload":"check/aaaaaaaaaabbbbbbbbbbcccccccccc12", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message

#test with content base64 encoded :
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.psa.messagingagent.echo.0", "recorded_at":78364, "payload":"L3Rlc3QvZWNoby9mb3IvbWU/ZGE9Ymxl", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.services.agps_agent", "recorded_at":78364, "payload":"Y2hlY2svYWFhYWFhYWFhYWJiYmJiYmJiYmJjY2NjY2NjY2NjMTI=", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message
#protogen: curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d $'{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.services.protogen_fun_agent", "recorded_at":78364, "payload":"gqR0eXBlAaNtc2eCpG5hbWWvbXlsaXR0bGVyZXF1ZXN0p2xhdGxpc3STAQID", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message
post '/message' do
  hashData = welcome_new_data_from_outside(1, request)
  handle_msg_from_device('message', hashData)
  response.body = '{}'
end

#test:
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"sender":"351777047016827", "id":19, "data":[{"reset":true, "3":"V", "14":"\u0001", "recorded_at":1368449272}, {"recorded_at":1368449279, "24":"", "23":""}, {"recorded_at":1368449340}, {"recorded_at":1368449400}, {"recorded_at":1368449460}, {"recorded_at":1368449520}, {"recorded_at":1368449580}, {"recorded_at":1368449640}, {"recorded_at":1368449766}, {"recorded_at":1368449826}, {"recorded_at":1368449886}, {"recorded_at":1368449946}, {"recorded_at":1368450006}, {"recorded_at":1368450066}, {"recorded_at":1368450310}, {"recorded_at":1368450369}, {"recorded_at":1368450429}, {"recorded_at":1368450489}, {"recorded_at":1368497096}, {"recorded_at":1368497276}, {"recorded_at":1368497336}, {"recorded_at":1368497396}, {"recorded_at":1368497456}, {"recorded_at":1368497576}, {"recorded_at":1368497637}, {"recorded_at":1368497697}, {"recorded_at":1368497757}, {"recorded_at":1368497817}, {"recorded_at":1368497877}, {"recorded_at":1368497996}, {"recorded_at":1368498116}], "asset":"351777047016827"}}' http://localhost:5001/track
post '/track' do
  hashData = welcome_new_data_from_outside(2, request)
  handle_msg_from_device('track', hashData)
  response.body = '{}'
end

#test:
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"agent":"agps_agent", "order":"refresh_agps_files"}' http://localhost:5001/remote_call
post '/remote_call' do
  hashData = welcome_new_data_from_outside(3, request)
  handle_msg_from_device('order', hashData)
  response.body = '{}'
end

# todo: POST is more meaningful for this
# but then we have to deal with problems like CRSF and XSS
# todo: refactor, method too long
get '/start_tests' do
  unless params.has_key?("agents")
    halt(400, "'agents' parameter is mandatory")
  end
  agents_array = params['agents']
  unless agents_array.size >= 1
    halt(400, "'agents' parameters must include at least one agent")
  end
  CC.logger.info("Starting tests for agents " + agents_array.inspect)
  TestsRunner.instance.start_tests(agents_array)
  "Tests started for agents " + agents_array.inspect
end

get '/stop_tests' do
  TestsRunner.instance.stop_tests
  "Tests stopped"
end

get '/is_alive' do
  "I'm alive!"
end