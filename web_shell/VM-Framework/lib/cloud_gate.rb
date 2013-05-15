
def wrap_message(msg)
  meta = { 'account' => 'vm-sdk'}
  {'meta' => meta, 'payload' => msg}
end


def push_something_to_device(something)
  CC_SDK.logger.debug("Server: push_something_to_device:\n#{something}")

  $mutex_message_to_device.synchronize do
    $message_to_device << wrap_message(something)
  end
end

def push_ack_to_device(payload)
  begin
    CC_SDK.logger.debug("Server: push_ack_to_device: creating new ack message")

    tmp_id_from_device = payload['id']

    parent_id = CC_SDK.indigen_next_id

    payload['id'] = parent_id

    channel_str = payload['channel']

    channel_int = $dyn_channels[channel_str]
    if channel_str == nil || channel_int == nil
      CC_SDK.logger.error("Server: push_ack_to_device: error dyn channel #{channel_str} not found.")

      errorDynChannelMsg = Message.new()
      errorDynChannelMsg['id'] = CC_SDK.indigen_next_id
      errorDynChannelMsg['sender'] = 'sdk-server'
      errorDynChannelMsg['asset'] = nil
      errorDynChannelMsg['type'] = 'dynchannelsmessage'
      errorDynChannelMsg['payload'] = { "#{channel_str}" => -1}.to_json
      push_something_to_device(errorDynChannelMsg)
      return
    end
    CC_SDK.logger.debug("Server: push_ack_to_device: for channel #{channel_str} using number #{channel_int}")

    msgAck = Message.new(payload) #just to have a message struct, buts beurk ! todo: fix it
    ack_map = Hash.new()
    ack_map['channel'] =  channel_int
    ack_map['channelStr'] = channel_str
    ack_map['tmpId'] = tmp_id_from_device
    ack_map['msgId'] = parent_id

    msgAck['payload'] = ack_map.to_json
    msgAck['type'] = 'ackmessage'

    CC_SDK.logger.debug("Server: push_ack_to_device: adding Ack message with tmpId=#{ack_map['tmpId']} and msgId=#{ack_map['msgId']}")

    push_something_to_device(msgAck)

  rescue Exception => e
    CC_SDK.logger.error("Server: push_ack_to_device error while tracking with payload = \n#{payload}")
    print_ruby_exeption(e)
  end
end

def handle_msg_from_device(type, params)
  CC_SDK.logger.debug("Server: handle_msg_from_device: of type #{type}:\n#{params}")

  meta = params['meta']
  payload = params['payload']
  account = meta['account']

  CC_SDK.logger.debug("Server: handle_msg_from_device: success parse\n")

  case type
  when 'presence'
    handle_presence(meta, payload, account)
  when 'tracking'
    # Ack mesage
    push_ack_to_device(payload)

    handle_track(meta, payload, account)
  when 'message'
    # Ack mesage
    push_ack_to_device(payload)

    handle_message(meta, payload, account)
  else
    CC_SDK.logger.error('Server: handle_msg_from_device: type unknown')
  end

  CC_SDK.logger.debug("Server: handle_msg_from_device: success")
end
