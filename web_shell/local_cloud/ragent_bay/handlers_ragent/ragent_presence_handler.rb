class RagentPresenceHandler < MobileAgent::Base
  def handle_message_callback(meta, payload)
    params = {'meta' => meta, 'payload'=> payload}
    SDK_STATS.stats['server']['pulled_from_queue'][0] += 1
    RagentIncomingMessage.handle_presence(params)
  end
end
