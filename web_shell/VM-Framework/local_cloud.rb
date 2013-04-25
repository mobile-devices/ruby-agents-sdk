#!/usr/bin/ruby -w
require 'sinatra'
require 'json'
require 'thread'
require 'logger'

require_relative 'ID_Generator'
include ID_GEN
require_relative 'message'
require_relative '../scripts/agents_mgt'

# re-generate all agents wrapper
generate_agents

require_relative '../cloud_agents_generated/generated'
require_relative 'cloud_gate'

$dyn_channels = generated_get_dyn_channel

$message_to_device = []
$mutex_message_to_device = Mutex.new()

$main_server_logger = Logger.new('ruby-agents-sdk.log', 10, 1 * 1024 * 1024)

def get_json_from_request(request)
  begin
    request.body.rewind  # in case someone already read it
    JSON.parse(request.body.read)
  rescue
    $main_server_logger.error('error while reading json')
    nil
  end
end

# Go !
$main_server_logger.info("starting sinatra with #{get_run_agents().join(';')} agents")


#test: curl localhost:5001/dynamic_channel_request
get '/dynamic_channel_request' do
  msg = Message.new()
  msg.payload = $dyn_channels.clone.to_json
  msg.type = 'dynchannelsmessage'

  $main_server_logger.debug("/dynamic_channel_request has #{$dyn_channels.count} channels :\n#{msg.to_json}")
  msg.to_json
end

#test: curl localhost:5001/new_message_from_cloud
get '/new_message_from_cloud' do
  tmp_hash = Hash.new()
  $mutex_message_to_device.synchronize do
    tmp_hash = $message_to_device.clone
    $message_to_device.clear
  end
  $main_server_logger.debug("/new_message_from_cloud has #{tmp_hash.count} messages :\n#{tmp_hash.to_json}")
  tmp_hash.to_json
end

#test:
#curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"connect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
#curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"reconnect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
#curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"meta":{"account":"rubyTestAccount"}, "payload":{"id":438635746530689024,"sender":"mdi_device","asset":null,"type":"disconnect","channel": "com.mdi.services.demo_echo_agent","payload":"hello_toto"}}' http://localhost:5001/presence
post '/presence' do
  $main_server_logger.debug("\n\n\n\n/presence new presence")

  jsonData = get_json_from_request(request)
  return if jsonData == nil

  begin
    handle_msg_from_device('presence', jsonData)
  rescue
    $main_server_logger.error('/presence error')
    response.status = 453
  end
end

post '/message' do
  $main_server_logger.debug("\n\n\n\n/message new message")

  jsonData = get_json_from_request(request)
  return if jsonData == nil

  begin
    handle_msg_from_device('message', jsonData)
  rescue
    $main_server_logger.error('/message error')
    response.status = 453
  end
end

post '/track' do
  $main_server_logger.debug("\n\n\n\n/track new track")

  jsonData = get_json_from_request(request)
  return if jsonData == nil

  begin
    handle_msg_from_device('track', jsonData)
  rescue
    $main_server_logger.error('/track error')
    response.status = 453
  end
end
