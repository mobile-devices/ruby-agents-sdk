#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

# An observable that enables setting callbacks when a message is sent ot a device
# When a message is sent, the observers will receive the signal :message_sent with the
# given message as a parameter (the message will be a hash)
class CloudGate

  # observer pattern
  @@observers = []

  def self.add_observer(obs)
    @@observers << obs unless @@observers.include?(obs)
  end

  def self.remove_observer(obs)
    @@observers.delete(obs)
  end

  def self.message_sent(msg)
    @@observers.each { |obs| obs.message_sent(msg) if obs.respond_to?(:message_sent) }
  end

  def self.id_generated(id, tempId)
    @@observers.each { |obs| obs.id_generated(id, tempId) if obs.respond_to?(:id_generated) }
  end

end


def push_something_to_device(something)
  CC.logger.debug("Server: push_something_to_device:\n#{something}")

  CloudGate.message_sent(something)

  # in fake mode, the content or a message must be base64 encode
  begin
    if something['payload']['type'] == 'message'
      something['payload']['payload'] = Base64.encode64(something['payload']['payload'])
    end
  rescue Exception => e
    CCS.print_ruby_exception(e)
  end

  $mutex_message_to_device.synchronize do
    $message_to_device << something
    SDK_STATS.stats['server']['in_queue'] = $message_to_device.size
  end
  SDK_STATS.stats['server']['total_queued'] += 1
  SDK_STATS.stats['server']['total_sent'] += 1
end

# side effect: set the true ID of the message
def push_ack_to_device(message)
  begin
    CC.logger.debug("Server: push_ack_to_device: creating new ack message")

    tmp_id_from_device = message.id

    parent_id = CC.indigen_next_id

    message.id = parent_id

    CloudGate.id_generated(message.id, tmp_id_from_device)

    channel_str = message.channel

    channel_int = $dyn_channels[channel_str]

    CC.logger.debug("Server: push_ack_to_device: for channel #{channel_str} using number #{channel_int}")

    msgAck = message.clone

    #msgAck = Message.new(payload) #just to have a message struct, buts beurk ! todo: fix it
    ack_map = Hash.new()
    ack_map['channel'] =  channel_int
    ack_map['channelStr'] = channel_str
    ack_map['tmpId'] = tmp_id_from_device
    ack_map['msgId'] = parent_id

    msgAck.content = ack_map.to_json
    msgAck.type = 'ackmessage'


    CC.logger.info("Server: push_ack_to_device: adding Ack message with tmpId=#{ack_map['tmpId']} and msgId=#{ack_map['msgId']}")

    push_something_to_device(msgAck.to_hash)
    SDK_STATS.stats['server']['total_ack_queued'] += 1
  rescue Exception => e
    CC.logger.error("Server: push_ack_to_device error with payload = \n#{message}")
    CCS.print_ruby_exception(e)
    return false
  end
  return true
end


def check_channel(channel_str)
  if channel_str.is_a? String
    channel_int = $dyn_channels[channel_str]
    if channel_int == nil
      CC.logger.error("Server: check_channel: channel '#{channel_str}' not found. Available are:\n #{$dyn_channels}")
      return false
    end
  else
    CC.logger.error("Server: check_channel: channel is not type String : #{channel_str}")
    return false
  end
  return true
end


def handle_msg_from_device(type, params)
  # parse the message
  msg = nil
  case type
  when 'presence'
    begin
      msg = CCS::Presence.new(params)
      PUNK.end('a','ok','in',"SERVER <- PRESENCE '#{msg.type}'")
    rescue Exception => e
      CCS.print_ruby_exception(e)
      SDK_STATS.stats['server']['err_parse'][0] += 1
      PUNK.end('a','ko','in',"SERVER <- PRESENCE : parse params fail")
      SDK_STATS.stats['server']['total_error'] += 1
      return
    end
  when 'message'
    begin
      msg = CCS::Message.new(params)
      # we punk end further when channel is valid
    rescue Exception => e
      CCS.print_ruby_exception(e)
      SDK_STATS.stats['server']['err_parse'][1] += 1
      PUNK.end('a','ko','in',"SERVER <- MSG : parse params fail")
      SDK_STATS.stats['server']['total_error'] += 1
      return
    end
  when 'track'
    begin
      msg = CCS::Track.new(params)
      PUNK.end('a','ok','in',"SERVER <- TRACK")
    rescue Exception => e
      CCS.print_ruby_exception(e)
      SDK_STATS.stats['server']['err_parse'][2] += 1
      PUNK.end('a','ko','in',"SERVER <- TRACK : parse params fail")
      SDK_STATS.stats['server']['total_error'] += 1
      return
    end
  when 'order'
    begin
      msg = CCS::Order.new(params)
      PUNK.end('a','ok','in',"SERVER <- ORDER '#{msg.code}'")
    rescue CCS::AgentNotFound => e
      CCS.print_ruby_exception(e)
      response.body = 'service unavailable'
      SDK_STATS.stats['server']['remote_call_unused'] += 1
      PUNK.end('a','ko','in',"SERVER <- ORDER : agent not found")
      SDK_STATS.stats['server']['total_error'] += 1
      return
    rescue Exception => e
      CCS.print_ruby_exception(e)
      SDK_STATS.stats['server']['err_parse'][3] += 1
      PUNK.end('a','ko','in',"SERVER <- ORDER : parse params fail")
      SDK_STATS.stats['server']['total_error'] += 1
      return
    end
  end

  CC.logger.debug("Server: handle_msg_from_device: success parse\n")


  PUNK.start('handle','handling from device')

  # Process the message
  case type
  when 'presence'
    handle_presence(msg)
  when 'message'
    # let's drop all message with channel 0 :
    if (msg.channel == '0')
      CC.logger.info('received a message with channel 0, dropping it')
      return
    end

    # check channel
    if !(check_channel(msg.channel))
      SDK_STATS.stats['server']['err_dyn_channel'][1] += 1
      SDK_STATS.stats['server']['total_error'] += 1
      PUNK.end('a','ko','in',"SERVER <- MSG[#{crop_ref(msg.id, 4)}] : channel not found")
      return
    end

    PUNK.end('a','ok','in',"SERVER <- MSG[#{crop_ref(msg.id, 4)}]")

    # Ack mesage
    PUNK.start('ack')
    if !(push_ack_to_device(msg))
      SDK_STATS.stats['server']['err_while_send_ack'][1] += 1
      SDK_STATS.stats['server']['total_error'] += 1
      PUNK.end('ack','ko','out',"SERVER -> ACK : fail")
      return
    end
    SDK_STATS.stats['server']['ack_sent_to_device'][1] += 1
    PUNK.end('ack','ok','out',"SERVER -> ACK")

    handle_message(msg)
  when 'track'
    handle_track(msg)
  when 'order'
    handle_order(msg)
  else
    CC.logger.error('Server: handle_msg_from_device: type unknown')
  end

  CC.logger.info("Server: handle_msg_from_device: success")
end
