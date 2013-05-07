#!/usr/bin/ruby -w
require 'sinatra'
set :bind, '0.0.0.0'
set :port, '5001'
require 'json'
require 'thread'
require 'logger'
require 'redis'
require 'redis-namespace'

require_relative 'lib/cloud_connect_sdk_module'
include CC_SDK
require_relative 'lib/message'
require_relative '../scripts/agents_mgt'

# re-generate all agents wrapper
generate_agents

require_relative '../cloud_agents_generated/generated'
require_relative 'lib/cloud_gate'

$dyn_channels = generated_get_dyn_channel

$message_to_device = []
$mutex_message_to_device = Mutex.new()

$main_server_root_path = File.expand_path("..", __FILE__)


def get_json_from_request(request)
  begin
    request.body.rewind  # in case someone already read it
    JSON.parse(request.body.read)
  rescue
    CC_SDK.logger.error('Server: error while reading json')
    nil
  end
end


# Go !
agents_list_str=""
get_run_agents().each { |agent|
  agents_list_str+="|   * #{agent}\n"
}
CC_SDK.logger.info("\n\n\n\n\n+===========================================================\n| starting ruby-agent-sdk-server with #{get_run_agents().count} agents:\n#{agents_list_str}\n+===========================================================")


#test: curl localhost:5001/dynamic_channel_request
get '/dynamic_channel_request' do
  msg = Message.new()
  msg.payload = $dyn_channels.clone.to_json
  msg.type = 'dynchannelsmessage'

  CC_SDK.logger.debug("Server: /dynamic_channel_request has #{$dyn_channels.count} channels :\n#{msg.to_json}")
  msg.to_json
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

#test:
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"connect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"reconnect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
#curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"disconnect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
post '/presence' do
  CC_SDK.logger.debug("\n\n\n\nServer: /presence new presence")

  jsonData = get_json_from_request(request)
  if jsonData == nil
    response.body = 'error while parsing json'
    return
  end
  begin
    handle_msg_from_device('presence', jsonData)
    response.body = 'success'
  rescue
    CC_SDK.logger.error('Server: /presence error')
    response.body = 'error while processing presence'
  end

end

post '/message' do
  CC_SDK.logger.debug("\n\n\n\nServer: /message new message")

  jsonData = get_json_from_request(request)
  if jsonData == nil
    response.body = 'error while parsing json'
    return
  end
  begin
    handle_msg_from_device('message', jsonData)
    response.body = 'success'
  rescue
    CC_SDK.logger.error('Server: /message error')
    response.body = 'error while processing message'
  end
end

post '/track' do
  CC_SDK.logger.debug("\n\n\n\nServer: /track new track")

  jsonData = get_json_from_request(request)
  if jsonData == nil
    response.body = 'error while parsing json'
    return
  end
  begin
    handle_msg_from_device('track', jsonData)
    response.body = 'success'
  rescue
    CC_SDK.logger.error('Server: /track error')
    response.body = 'error while processing track'
  end
end
