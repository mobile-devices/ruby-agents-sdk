##### Agent requires ##################################################

#todo: auto require recursively all *.rb in lib folder (put this code somewhere else)

##### General guide-line ##############################################
# dev it stateless
# one file in lib per work
# on message receieve get new_message_from_device ....
# to send a message to device, use :
#   send_message_to_device(account, asset, content)
#   reply_message_to_device(message, account, content)
# to configure the dynamic channel used by this agent, go and edit config/dynamic_channel.yml
# if you need additional gems, edit the GemFile and require them here
# remember to complete the README.md
# to write some log, use the @logger class
# put our other ruby files in the lib folder

#######################################################################

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