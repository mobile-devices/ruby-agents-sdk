class RagentTrackHandler < MobileAgent::Base
  def handle_message_callback(meta, payload)
    params = {'meta' => meta, 'payload'=> payload}
    SDK_STATS.stats['server']['pulled_from_queue'][2] += 1
    RagentIncomingMessage.handle_track(params)
  end
end
