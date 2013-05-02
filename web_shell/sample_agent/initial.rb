

def new_presence_from_device(meta, payload, account)
  # Write your code here
  @logger.debug('initial:new_presence_from_device')
end


def new_message_from_device(meta, payload, account)
  msg = Message.new(payload)
  # Write your code here
  @logger.debug('initial:new_message_from_device')
end


def new_track_from_device(meta, payload, account)
  # Write your code here
  @logger.debug('initial:new_track_from_device')
end