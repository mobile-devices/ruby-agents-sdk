
def push_someting_to_device(something)
  puts "push_someting_to_device: #{something}"

  $mutex_message_to_device.synchronize do
    $message_to_device << something
  end
end

def push_ack_to_device(payload_src, tmp_id_from_device, parent_id)
  channel_str = payload_src.channel
  channel_int = $dyn_channels[channel_str]

  msgAck = new Message(payload_src) #just to have a message struct, buts beurk ! todo: fix it

  ack_map = Hash.new()
  ack_map['channel'] =  channel_int
  ack_map['channelStr'] = channel_str
  ack_map['tmpId'] = tmp_id_from_device
  ack_map['msgId'] = parent_id

  msgAck.payload = ack_map.to_json
  msgAck.type = 'ackmessage'

  push_someting_to_device(ack_map)

  puts "push_ack_to_device: added Ack message with tmpId=#{ack_map['tmpId']} a,d msgId=#{ack_map['msgId']}"
  puts "push_ack_to_device: Ack = #{ack_map}"
end


def handle_msg_from_device(type, param)

  meta = param['meta']
  payload = param['payload']
  tmp_id_from_device = payload.id
  account = meta['account']

  parent_id = ID_GEN.next_id()
  payload.id = parent_id

  push_ack_to_device(payload, tmp_id_from_device, parent_id)

  case type
  when 'presence'
    handle_presence(meta, payload, account)
  when 'tracking'
    handle_track(meta, payload, account)
  when 'message'
    handle_message(meta, payload, account)
  else
    'f*ck'
  end

  puts "handle_msg_from_device: done tmpId=#{tmp_id_from_device} parrent_id=#{parent_id}"
end
