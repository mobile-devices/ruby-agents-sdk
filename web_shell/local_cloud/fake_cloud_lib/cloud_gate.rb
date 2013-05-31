#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

def wrap_message(msg)
  meta = { 'account' => 'vm-sdk'}
  {'meta' => meta, 'payload' => msg}
end


def push_something_to_device(something)
  CC_SDK.logger.debug("Server: push_something_to_device:\n#{something}")

  $mutex_message_to_device.synchronize do
    $message_to_device << wrap_message(something)
    SDK_STATS.stats['server']['in_queue'] = $message_to_device.size
  end
  SDK_STATS.stats['server']['total_queued'] += 1
  SDK_STATS.stats['server']['total_sent'] += 1
end

def push_ack_to_device(payload)
  begin
    CC_SDK.logger.debug("Server: push_ack_to_device: creating new ack message")

    tmp_id_from_device = payload['id']

    parent_id = CC_SDK.indigen_next_id

    payload['id'] = parent_id

    channel_str = payload['channel']

    channel_int = $dyn_channels[channel_str]

    CC_SDK.logger.debug("Server: push_ack_to_device: for channel #{channel_str} using number #{channel_int}")

    msgAck = Message.new(payload) #just to have a message struct, buts beurk ! todo: fix it
    ack_map = Hash.new()
    ack_map['channel'] =  channel_int
    ack_map['channelStr'] = channel_str
    ack_map['tmpId'] = tmp_id_from_device
    ack_map['msgId'] = parent_id

    msgAck['payload'] = ack_map.to_json
    msgAck['type'] = 'ackmessage'

    CC_SDK.logger.info("Server: push_ack_to_device: adding Ack message with tmpId=#{ack_map['tmpId']} and msgId=#{ack_map['msgId']}")

    push_something_to_device(msgAck)
    SDK_STATS.stats['server']['total_ack_queued'] += 1
  rescue Exception => e
    CC_SDK.logger.error("Server: push_ack_to_device error with payload = \n#{payload}")
    print_ruby_exeption(e)
    return false
  end
  return true
end


def check_channel(payload)
  channel_str = payload['channel']
  if channel_str.is_a? String
    channel_int = $dyn_channels[channel_str]
    if channel_int == nil
      CC_SDK.logger.error("Server: check_channel: channel #{channel_str} not found. Available are:\n #{$dyn_channels}")
      return false
    end
  else
    CC_SDK.logger.error("Server: check_channel: channel is not type String : #{channel_str}")
    return false
  end
  return true
end


def handle_msg_from_device(type, params)
  CC_SDK.logger.info("Server: handle_msg_from_device: of type #{type}:\n#{params}")

  begin
    meta = params['meta']
    payload = params['payload']
    account = meta['account']
  rescue Exception => e
    print_ruby_exeption(e)
    case type
    when 'presence'
      SDK_STATS.stats['server']['err_parse'][0] += 1
      PUNK.end('a','ko','in',"SERVER <- PRESENCE : parse params fail")
    when 'message'
      SDK_STATS.stats['server']['err_parse'][1] += 1
      PUNK.end('a','ko','in',"SERVER <- MSG : parse params fail")
    when 'track'
      SDK_STATS.stats['server']['err_parse'][2] += 1
      PUNK.end('a','ko','in',"SERVER <- TRACK : parse params fail")
    end
    SDK_STATS.stats['server']['total_error'] += 1
    return
  end

  CC_SDK.logger.debug("Server: handle_msg_from_device: success parse\n")

  case type
  when 'presence'
    PUNK.end('a','ok','in',"SERVER <- PRESENCE")
    handle_presence(meta, payload, account)
  when 'message'
    # check channel
    if !(check_channel(payload))
      SDK_STATS.stats['server']['err_dyn_channel'][1] += 1
      SDK_STATS.stats['server']['total_error'] += 1
      PUNK.end('a','ko','in',"SERVER <- MSG : channel not found")
      return
    end

    PUNK.end('a','ok','in',"SERVER <- MSG")

    # Ack mesage
    PUNK.start('ack')
    if !(push_ack_to_device(payload))
      SDK_STATS.stats['server']['err_while_send_ack'][1] += 1
      SDK_STATS.stats['server']['total_error'] += 1
      PUNK.end('ack','ko','out',"SERVER -> ACK : fail")
      return
    end
    SDK_STATS.stats['server']['ack_sent_to_device'][1] += 1
    PUNK.end('ack','ok','out',"SERVER -> ACK")

    handle_message(meta, payload, account)
  when 'track'
    PUNK.end('a','ok','in',"SERVER <- TRACK")

    handle_track(meta, payload, account)
  else
    CC_SDK.logger.error('Server: handle_msg_from_device: type unknown')
  end

  CC_SDK.logger.info("Server: handle_msg_from_device: success")
end
