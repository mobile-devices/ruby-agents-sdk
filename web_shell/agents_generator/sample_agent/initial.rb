module Initial_agent_XXProjectName

  def new_presence_from_device(meta, payload, account)
    # Write your code here
    log_debug('initial:new_presence_from_device')
  end


  def new_message_from_device(meta, payload, account)
    msg = Message.new(payload)
    # Write your code here
    log_debug('initial:new_message_from_device')
  end


  def new_track_from_device(meta, payload, account)
    # Write your code here
    log_debug('initial:new_track_from_device')
  end


  def new_order(order, params)
    # Write your code here
    log_debug('initial:remote_call')
  end

end