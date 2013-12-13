class RagentMessageHandler < MobileAgent::Base
  def handle_message_callback(meta, payload)
    params = { meta: meta, payload: payload}
    SDK_STATS.stats['server']['pulled_from_queue'][1] += 1
    RagentIncomingMessage.handle_message(params)
  end
end
