#!/usr/bin/ruby -w

###################################################################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
###################################################################################################

require 'sinatra'
set :bind, '0.0.0.0'
set :port, '5001'
require 'json'
require 'thread'

$main_server_root_path = File.expand_path("..", __FILE__)

## FAKE CLOUD LIB #################################################################################

require 'active_support/all'

require_relative 'fake_cloud_lib/cloud_connect_sdk_module'
include CC_SDK

require_relative 'fake_cloud_lib/message'
require_relative 'fake_cloud_lib/cloud_gate'


## API ############################################################################################
require_relative 'API/sdk_stats'
include SDK_STATS

#### Agent generation #############################################################################
require_relative '../agents_generator/agents_mgt'
include GEN

CC_SDK.logger.info("\n\n\n\n\n")

# re-generate all agents wrapper
GEN.generate_agents

CC_SDK.logger.info("agents generation successful")

## bundle install #################################################################################

# merge Gemfile (into generate_agents)


# bundle install

`cd ../agents_generator/cloud_agents_generated;bundle install`
CC_SDK.logger.info("bundle install done")

## Generate cron tasks ############################################################################

crons = GEN.generated_get_agents_whenever_content
File.open("#{$main_server_root_path}/config/schedule.rb", 'w') { |file| file.write(crons) }
`bundle exec whenever -w`

#### Init server ##################################################################################

# include main
require_relative '../agents_generator/cloud_agents_generated/generated'

# dynamic channel
$dyn_channels = GEN.generated_get_dyn_channel

# message queue to device
$message_to_device = []
$mutex_message_to_device = Mutex.new()

# reset starts
SDK_STATS.reset_stats

agents_list_str=""
get_run_agents().each { |agent|
  agents_list_str+="|   . #{agent}\n"
}
CC_SDK.logger.info("\n\n+===========================================================\n| starting ruby-agent-sdk-server with #{get_run_agents().count} agents:\n#{agents_list_str}+===========================================================\n")


CC_SDK.logger.info("ruby-agent-sdk-server ready !\n\n")

###################################################################################################

def get_json_from_request(request)
  to_parse = ""
  begin
    request.body.rewind  # in case someone already read it
    to_parse = request.body.read
    JSON.parse(to_parse)
  rescue Exception => e
    CC_SDK.logger.error("Server: error while reading json (len=#{to_parse.length}) \n #{to_parse}")
    print_ruby_exeption(e)
    nil
  end
end

#test: curl localhost:5001/dynamic_channel_request
get '/dynamic_channel_request' do
  msg = Message.new()
  msg.payload = $dyn_channels.clone.to_json
  msg.type = 'dynchannelsmessage'

  wrapped = wrap_message(msg)

  CC_SDK.logger.debug("Server: /dynamic_channel_request has #{$dyn_channels.count} channels :\n#{wrapped.to_json}")
  wrapped.to_json
end


#test: curl -i localhost:5001/new_message_from_cloud
get '/new_message_from_cloud' do
  tmp_hash = Hash.new()
  $mutex_message_to_device.synchronize do
    tmp_hash = $message_to_device.clone
    $message_to_device.clear
  end
  CC_SDK.logger.debug("Server: /new_message_from_cloud has #{tmp_hash.count} messages :\n#{tmp_hash.to_json}")
  tmp_hash.to_json
end

#test : curl http://localhost:5001/sdk_stats
get '/sdk_stats' do
  SDK_STATS.stats.to_json
end


#test:
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"connect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"reconnect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"disconnect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
post '/presence' do
  SDK_STATS.stats['server']['received'][0] += 1
  CC_SDK.logger.debug("\n\n\n\nServer: /presence new presence")
  jsonData = get_json_from_request(request)
  if jsonData == nil
    response.body = 'error while parsing json'
    SDK_STATS.stats['server']['err_parse'][0] += 1
    return
  end
  handle_msg_from_device('presence', jsonData)
end

#test:
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.psa.messagingagent.echo.0", "recorded_at":78364, "payload":"/test/echo/for/me?da=ble", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"timeout":120, "sender":"351777047016827", "id":-2,"type":"message", "channel":"com.mdi.services.agps_agent", "recorded_at":78364, "payload":"check/aaaaaaaaaabbbbbbbbbbcccccccccc12", "asset":"351777047016827", "parent_id":-1}}' http://localhost:5001/message
post '/message' do
  SDK_STATS.stats['server']['received'][1] += 1
  CC_SDK.logger.debug("\n\n\n\nServer: /message new message")
  jsonData = get_json_from_request(request)
  if jsonData == nil
    response.body = 'error while parsing json'
    SDK_STATS.stats['server']['err_parse'][1] += 1
    return
  end
  handle_msg_from_device('message', jsonData)
  response.body = '{}'
end


#test:
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"mdi21dev"}, "payload":{"sender":"351777047016827", "id":19, "data":[{"reset":true, "3":"V", "14":"\u0001", "recorded_at":1368449272}, {"recorded_at":1368449279, "24":"", "23":""}, {"recorded_at":1368449340}, {"recorded_at":1368449400}, {"recorded_at":1368449460}, {"recorded_at":1368449520}, {"recorded_at":1368449580}, {"recorded_at":1368449640}, {"recorded_at":1368449766}, {"recorded_at":1368449826}, {"recorded_at":1368449886}, {"recorded_at":1368449946}, {"recorded_at":1368450006}, {"recorded_at":1368450066}, {"recorded_at":1368450310}, {"recorded_at":1368450369}, {"recorded_at":1368450429}, {"recorded_at":1368450489}, {"recorded_at":1368497096}, {"recorded_at":1368497276}, {"recorded_at":1368497336}, {"recorded_at":1368497396}, {"recorded_at":1368497456}, {"recorded_at":1368497576}, {"recorded_at":1368497637}, {"recorded_at":1368497697}, {"recorded_at":1368497757}, {"recorded_at":1368497817}, {"recorded_at":1368497877}, {"recorded_at":1368497996}, {"recorded_at":1368498116}], "asset":"351777047016827"}}' http://localhost:5001/track
post '/track' do
  SDK_STATS.stats['server']['received'][2] += 1
  CC_SDK.logger.debug("\n\n\n\nServer: /track new track")
  jsonData = get_json_from_request(request)
  if jsonData == nil
    response.body = 'error while parsing json'
    SDK_STATS.stats['server']['err_parse'][2] += 1
    return
  end
  handle_msg_from_device('track', jsonData)
end

