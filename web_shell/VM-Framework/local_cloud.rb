#!/usr/bin/ruby -w
require 'sinatra'
require 'json'
require 'thread'

require_relative 'ID_Generator'
require_relative 'message'
require_relative '../scripts/agents_mgt'

# re-generate all agents wrapper
generate_agents

require_relative '../cloud_agents_generated/generated'
require_relative 'cloud_gate'

$dyn_channels = generated_get_dyn_channel

$message_to_device = Hash.new()
$mutex_message_to_device = Mutex.new()

# Go !
puts "starting sinatra with #{get_run_agents().join(';')} agents"

puts 'local_cloud started'

# give all the channel str to int
get '/dynamic_channel_request' do
  test_alter_agents
  $dyn_channels.to_json
end

get '/new_message_from_cloud' do
  tmp_hash = Hash.new()
  $mutex_message_to_device.synchronize do
    tmp_hash = $message_to_device.clone
    $message_to_device.clear
  end
  tmp_hash.to_json
end

#curl example :
# curl

post '/presence' do
  begin
    handle_msg_from_device('presence', param)
  rescue
    puts 'error on /presence'
    response.status = 453
  end
end

post '/message' do
  begin
    handle_msg_from_device('message', param)
  rescue
    puts 'error on /message'
    response.status = 453
  end
end

post '/track' do
  begin
    handle_msg_from_device('track', param)
  rescue
    puts 'error on /tracking'
    response.status = 453
  end
end



