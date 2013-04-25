
def push_someting_to_device(something)
  $main_server_logger.debug("push_someting_to_device:\n#{something}")

  $mutex_message_to_device.synchronize do
    $message_to_device << something
  end
end

def push_ack_to_device(payload_src, tmp_id_from_device, parent_id)

  $main_server_logger.debug("push_ack_to_device: creating new ack message")

  channel_str = payload_src['channel']

  channel_int = $dyn_channels[channel_str]
  if channel_str == nil || channel_int == nil
    $main_server_logger.error("push_ack_to_device: error dyn channel #{channel_str} not found.")
  end
  $main_server_logger.debug("push_ack_to_device: for channel #{channel_str} using number #{channel_int}")

  msgAck = Message.new(payload_src) #just to have a message struct, buts beurk ! todo: fix it
  ack_map = Hash.new()
  ack_map['channel'] =  channel_int
  ack_map['channelStr'] = channel_str
  ack_map['tmpId'] = tmp_id_from_device
  ack_map['msgId'] = parent_id

  msgAck['payload'] = ack_map.to_json
  msgAck['type'] = 'ackmessage'

  $main_server_logger.debug("push_ack_to_device: adding Ack message with tmpId=#{ack_map['tmpId']} and msgId=#{ack_map['msgId']}")

  push_someting_to_device(msgAck)
end


def handle_msg_from_device(type, params)
  $main_server_logger.debug("handle_msg_from_device: of type #{type}:\n#{params}")

  meta = params['meta']
  payload = params['payload']
  tmp_id_from_device = payload['id']
  account = meta['account']

  $main_server_logger.debug('handle_msg_from_device: success parse')

  parent_id = ID_GEN.next_id()
  payload['id'] = parent_id

  push_ack_to_device(payload, tmp_id_from_device, parent_id)

  case type
  when 'presence'
    handle_presence(meta, payload, account)
  when 'tracking'
    handle_track(meta, payload, account)
  when 'message'
    handle_message(meta, payload, account)
  else
    $main_server_logger.error('handle_msg_from_device: type unknown')
  end

  $main_server_logger.debug("handle_msg_from_device: done tmpId=#{tmp_id_from_device} parrent_id=#{parent_id}")
end
