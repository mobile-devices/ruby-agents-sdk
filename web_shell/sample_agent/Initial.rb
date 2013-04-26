#!/usr/bin/ruby -w
require_relative 'Message_gate'

# XXProjectName agent
class Agent_XXProjectName

  ##### Framework requiries #############################################
  @agent_name = 'XXProjectName'
  @logger = nil
  @CHANNEL = 'com.mdi.services.XXProjectName'
  @root_dir = nil
  include MessageGate_XXProjectName

  def initialize() # constructor
    @logger = Logger.new('ruby_log_XXProjectName.log', 10, 1 * 1024 * 1024)

    # init root dir
    @root_dir = File.expand_path("..", __FILE__)
    @logger.debug("Agent_XXProjectName root path is  = #{@root_dir}")

    # Load dynamic channel
    cnf = YAML::load(File.open("#{@root_dir}/config/dynamic_channel.yml"))
    @CHANNEL = cnf['Channel_str']
    @logger.debug("Agent_XXProjectName init with dynamic channel = \"#{@CHANNEL}\"")
  end
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
  # if you need additional gems, edit the GemFile
  # remember to complete the README.md

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
