#MessageGate
require 'yaml'


module MessageGate_XXProjectName
  #todo : to fix
  #cnf = YAML::load(File.open('./dynamic_channel.yml'))
  #CHANNEL = cnf['Channel_str']
  @CHANNEL = 'com.mdi.services.XXProjectName'

  ######### Messages from devices #######################
  def handle_message(meta, payload, account)
    return unless payload['type'] == "message"
    return unless payload['channel'] == @CHANNEL

    new_message_from_device(meta, payload, account)
  end

  def handle_presence(meta, payload, account)
    new_presence_from_device(meta, payload, account)
  end

  def handle_track(meta, payload, account)
    new_track_from_device(meta, payload, account)
  end

  ########## Messages to devices ########################
  def send_message_to_device(account, asset, content)
    account.messages.new({
      asset:     asset.imei,
      recipient: asset.imei,
      sender:    '@@server@@',
      channel:   @CHANNEL,
      payload:   content.to_msgpack
      }, as: :agent).push
  end

  def reply_message_to_device(message, account, content)
    #idem, we build a Message then send it to rqueue
    m = message.reply("200#{content}")
    m.push('account' => account.name)
  end

  #######################################################

end