#!/usr/bin/ruby -w

require_relative 'Message_gate'


# XXProjectName agent
class Agent_XXProjectName

  ##### Framework requiries #############################################
  @agent_name = 'XXProjectName'
  include MessageGate_XXProjectName

  ##### Agent requires ##################################################

  #todo: auto require recursively all *.rb in lib folder (put this code somewhere else)

  ##### General guide-line ##############################################
  # dev it stateless
  # one file in lib per work
  # on message receieve get new_message_from_device ....
  # to send a message to device, use :
  #   send_message_to_device(account, asset, content)
  #   reply_message_to_device(message, account, content)

  #######################################################################

  def new_message_from_device(meta, payload, account)
    msg = Message.new(payload)
    # Write your code here
  end

  def new_presence_from_device(meta, payload, account)
    # Write your code here
  end

  def new_track_from_device(meta, payload, account)
    # Write your code here
  end

end
