
require 'base64'
require 'json'

require_relative 'test_runner'
require_relative 'json_tests_writer'
require_relative 'atomic_write'


# Require the protogen APIS
# Will be useful in this code but also enables the user to use them just by requiring tests_helper
Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "agents_generator", "cloud_agents_generated", "protogen*"))) do |filename|
  if File.exist?(File.join(filename, "protogen_apis.rb"))
    require_relative File.join(filename, "protogen_apis")
  end
end





# @api public
# Provides several utilities to write unit tests inside the SDK.
# @note Methods and classes of this module are intended to be used in automated tests only!
#   Do not use this module in your code otherwise, as its inner behaviour may differ between environments.
module TestsHelper

  def api
    RAGENT.api
  end

  # @!group Helper methods

  # Helper to test asynchronous behaviour.
  #
  # This method executes the given block at given time intervals until the block returns without raising an exception.
  # If an exception is raised, it will catch it and ignore it unless elapsed time since the first attempt exceeds the given duration.
  # @param [Block] block a block to execute.
  # @param [Fixnum] elapsed_time internal use.
  # @param [Fixnum] increment duration in seconds between two attempts.
  # @param [Fixnum] time duration in seconds to wait for before aborting
  #    (this duration does not include the time the block will take to return or to raise an exception).
  # @example Basic usage with RSpec
  #    wait_for { a.should == b }
  # @example Real example with the SDK: check that an agent stores in redis the received presences
  #   presence = TestsHelper::PresenceFromDevice.new("connect", "1234")
  #   presence.send_to_server
  #   TestsHelper.wait_for { SDK.API::redis.get(presence.asset).should == presence.time.to_s}
  # @api public
  def self.wait_for(time = 5, increment = 1, elapsed_time = 0, &block)
    begin
      yield
    rescue Exception
      if elapsed_time >= time
        raise $!, "#{$!} (waited for #{elapsed_time} seconds)", $!.backtrace
      else
        sleep increment
        wait_for(time, increment, elapsed_time + increment, &block)
      end
    end
  end

  # Waits for server responses to a given device message and return these reponses.
  # This is (obviously) a blocking call.
  # @param [CloudConnectServices::Message] message the message sent by the device
  # @param [Fixnum, nil] number_of_responses if `nil`, wait until timeout and return all responses.
  #   If a `Fixnum`, return as soon as `number_of_responses` responses are sent.
  # @param [Fixnum] timeout this method will return after `timeout` seconds.
  # @return [Array<CloudConnectServices::Message>] messages sent by the server in response to the given message
  # @note Protogen messages are sent as multiple messages by the server.
  #   However, this method will consider all these small messages as a big one, so you don't have to worry
  #   about using Protogen or not.
  # @api public
  def self.wait_for_responses(message, number_of_responses = 1, timeout = 5)
    if (not number_of_responses.nil?) && number_of_responses <= 0
      raise ArgumentError.new("You must wait for at least 1 response message (given: #{number_of_responses})")
    end
    id_to_look_for = @@mappings[message.id]
    start_time = Time.now.to_f
    res = []
    while Time.now.to_f - start_time < timeout
      res = @@messages.select{ |msg| msg.parent_id == id_to_look_for }
      break if (not number_of_responses.nil?) && res.length >= number_of_responses
      sleep(0.1)
    end
    return res
  end

  # Returns the next messages sent by a device with the given asset.
  # @param [Fixnum] asset the IMEI or similar unique identifier of the device.
  # @param [Fixnum, nil] number_of_messages if `nil`, wait until timeout and return all messages.
  #   If a `Fixnum`, return as soon as `number_of_messages` messages are sent.
  # @param timeout (see TestsHelper.wait_for_responses).
  # @param [Array] type class of messages to be retrieved.
  # @return [Array] messages sent by the device
  # @note Will also trigger on messages created from the code and sent with {TestsHelper::MessageFromDevice#send_to_server}.
  # @api public
  def self.wait_for_device_msg(asset, number_of_messages = 1, timeout = 5, type=[UserApis::Mdi::Dialog::PresenceClass, UserApis::Mdi::Dialog::MessageClass, UserApis::Mdi::Dialog::TrackClass])
    if (not number_of_messages.nil?) && number_of_messages <= 0
      raise ArgumentError.new("You must wait for at least 1 message (given: #{number_of_messages})")
    end
    start_time = Time.now.to_f
    res = []
    while Time.now.to_f - start_time < timeout
      res = @@device_msg.select{ |msg| msg.asset == asset && type.include?(msg.class)}
      break if (not number_of_messages.nil?) && res.length >= number_of_messages
      sleep(0.1)
    end
    return res
  end

  # @!endgroup

  # @!group Internal

  # @api private
  # An array with a limited maximum size.
  # Old elements are overriden first.
  class RingBuffer < Array
    attr_reader :max_size

    def initialize(max_size, enum = nil)
      @max_size = max_size
      enum.each { |e| self << e } if enum
    end

    def <<(el)
      if self.size < @max_size || @max_size.nil?
        super
      else
        self.shift
        self.push(el)
      end
    end

    alias :push :<<
  end

  # @api private
  # A key-value simple cache with a limited size
  # http://stackoverflow.com/questions/1933866/efficient-ruby-lru-cache
  class Cache
    attr_accessor :max_size

    def initialize(max_size = 20)
      @data = {}
      @max_size = max_size
    end

    def store(key, value)
      @data.store key, [0, value]
      age_keys
      prune
    end

    def []=(key, value)
      store(key, value)
    end

    def [](key)
      read(key)
    end

    def read(key)
      if value = @data[key]
        renew(key)
        age_keys
        value[1]
      end
    end

    def inspect
      "Max cache size: #{max_size} ; data: #{@data.inspect}"
      @data.inspect
    end

    private

    def renew(key)
      @data[key][0] = 0
    end

    def delete_oldest
      m = @data.values.map{ |v| v[0] }.max
      @data.reject!{ |k,v| v[0] == m }
    end

    def age_keys
      @data.each{ |k,v| @data[k][0] += 1 }
    end

    def prune
      delete_oldest if @data.size > @max_size
    end
  end

  # @api private
  @@messages = RingBuffer.new(100)
  # @api private
  @@device_msg = RingBuffer.new(100)
  # @api private
  # Mappings between devices temporary message IDs and the IDs set by the server.
  @@mappings = Cache.new(100)

  # @!endgroup

  # @api private
  # Outgoing messages are sent through this method (see cloud_gate.rb, push_something_to_device)
  # This method then fires relevant events depending on the received data.
  # @param [Hash] hash_data a hash representing a message, with content NOT base64-encoded
  # @return true if the message was correctly handled, false otherwise
  def self.push_to_test_gate(hash_data)
    begin
      # Handle ACK
      if hash_data['payload']['type'] == 'ackmessage'
        content = JSON.parse(hash_data['payload']['payload'])
        self.id_generated(content['msgId'], content['tmpId'])
        return true
      end

      # Handle regular message
      message = TestsHelper.api.mdi.dialog.create_new_message(hash_data)  # CCS::Message.new(hash_data)
      # Rebuild Protogen object
      # Find a channel the sender is listening to
      if message.sender == "@@server@@" # message is from an agent (server) to device
        channel = message.channel # the channel the sender is listening to is the same the sender is sending to
      elsif message.asset == "ragent" # message from an agent (server) to another agent
        channel = message.sender # sender field was set by ragent to the channel the message came from before being redirected
      else
        CC.logger.warn("TestsHelper: Message is not sent to device neither to server. Can not process it in tests utilities. Message data : #{hash_data}")
        return false
      end # this assumes agents do only "enrichment + redirection" of messages and do not send new messages to the cloud

      # Look for the agent who is listening on the identified channel
      # We store its name in the variable "sender_agent"
      cloud_agents_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "cloud_agents"))
      agents = get_last_mounted_agents
      sender_agent = nil
      agents.each do |agent_name|
        config_file = File.join(cloud_agents_path, agent_name, "config", "#{agent_name}.yml")
        next unless File.exist?(config_file)
        config = YAML.load_file(config_file)
        if config["development"]["dynamic_channel_str"] == channel
          sender_agent = agent_name
          break
        end
      end
      if sender_agent.nil?
        CC.logger.warn("TestsHelper: Impossible to find the agent (among currently running agents) who sent #{hash_data}.\nIf you are running unit tests, some tests that check for a server response may fail because of this error.")
        return false
      end

      # Use this agent protocol to decode Protogen
      begin
        protogenAPIs = Object.const_get("Protogen_#{sender_agent}").const_get("ProtogenAPIs")
        protogen = Object.const_get("Protogen_#{sender_agent}").const_get("Protogen")
        # Decode the message
        msg_type = ""
        # As we intercepted the message before it was Base64 encoded, we don't have to base64-decode it
        # We use our specific decoder ID not to interfere with the normal protogen decoding process
        msg, cookies = protogenAPIs.decode(message, "tests_helper")
        message.content = msg
        message.meta['protogen_cookies'] = cookies
        msg_type = msg.class
        if msg_type == protogen::MessagePartNotice
          # This is only a part of a message, nothing else to do
          return true
        end
      rescue NameError => e # raised by Object.const_get if Protogen for this agent is not defined
        CC.logger.info("TestsHelper: Protogen protocol not found when trying to decode an outgoing message from agent #{sender_agent} (#e.class.name}: #{e.message}), defaulting to a non-Protogen message")
      rescue protogen::UnknownMessageType => e
        # Protogen could not handle the message, so we store it as a regular one
        CC.logger.debug("TestsHelper: Protogen unknown message type, defaulting to non-Protogen message")
      rescue MessagePack::UnpackError => e
        # Protogen could not handle the message, so we store it as a regular one
        CC.logger.debug("TestsHelper: Protogen messagepack error, defaulting to non-Protogen message")
      end
      self.message_sent(message)
      return true
    rescue Exception => e
      # we don't want this method to propagate any exception, so we catch them and display a warning instead
      CC.logger.warn("TestsHelper: failed to handle an outgoing message.\nIf you are running unit tests, some tests that check for a server response may fail because of this error.")
      CC.logger.warn("TestsHelper: caught exception #{e.class.name}: #{e.message}")
      trace = e.backtrace.join("\n")
      CC.logger.warn("TestsHelper: trace was \n #{trace}")
      return false
    end
  end

  # @!group Callbacks

  # @api private
  # Callback called everytime a message is sent.
  # @param [CloudConnectServices::Message] msg the outgoing message
  def self.message_sent(msg)
    @@messages << msg
  end

  # @api private
  # Callback called everytime an ACK is pushed to the device.
  def self.id_generated(id, tempId)
    @@mappings[tempId] = id
  end

  # @api private
  # Callback called everytime the server receives a message.
  def self.incoming_message(msg)
    @@device_msg << msg
  end

  # @!endgroup

  # @!group Events helper

  # A simulated message that comes from a device.
  # @see CloudConnectServices::Message
  class MessageFromDevice < CCS::Message

    # @param [String] asset IMEI or unique identifier of the (simulated) device
    # @param [String] account account name to use
    # @param [String] content string with the content of the message
    # @param [String] channel the name of the communication channel
    def initialize(content, channel, asset = "123456789", account = "tests")
      super({'meta' => {"account" => account},
          'payload' => {
            'type' => 'message',
            'id' => '',
            'asset' => sender,
            'sender' => asset,
            'channel' =>  channel,
            'payload' => content
          },
          'account' => account
          })
    end

    # Send this message to the server.
    def send_to_server
      params = self.to_hash
      # handle_message_from_device needs a base64 encoded content
      # indeed, in generated.rb (from template_agent.rb_) handle_message decode64 the payload
      params['payload']['payload'] = Base64.encode64(params['payload']['payload'])
      `curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '#{params.to_json}' http://localhost:5001/message`
    end

  end

  # A wrapper around a Protogen object used to simulate Protogen messages from a device.
  class ProtogenFromDevice < MessageFromDevice

    # @param [Protogen::Message::] protogen_object Protogen object coming from the simulated device
    # @param [String] asset IMEI or other unique device identifier
    # @param [String] account account name to use
    # @param [String] channel the Protogen object will be received on this channel
    def initialize(protogen_object, channel, asset = "123456789", account = "tests")
      @protogen_object = protogen_object
      super(nil, channel, asset, account)
    end

    # Send the protogen object to the server, in several small messages if needed.
    def send_to_server
      # Find the correct encoder
      # todo: factorize
      cloud_agents_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "cloud_agents"))
      agents = get_last_mounted_agents
      sender_agent = nil
      agents.each do |agent_name|
        config_file = File.join(cloud_agents_path, agent_name, "config", "#{agent_name}.yml")
        config = YAML.load_file(config_file)
        if config["development"]["dynamic_channel_str"] == self.channel
          sender_agent = agent_name
          break
        end
      end
      if sender_agent.nil?
        raise ArgumentError.new("Impossible to find the correct protocol for the channel #{self.channel} to decode #{@protogen_object.class.name}. Make sure your configuration files (channels + Protogen) are correct.")
      end

      protogenAPIs = Object.const_get("Protogen_#{sender_agent}").const_get("ProtogenAPIs")
      self.content = @protogen_object

      encoded = protogenAPIs.encode(self)

      if encoded.is_a? String
        self.content = encoded
        super.send_to_server
      elsif encoded.is_a? Array
        encoded.each_with_index do |content, index|
          frg = MessageFromDevice.new(content, self.channel, self.asset, self.account)
          # The index of the last message sent must be the index of the original message
          # because it allows correct detection of the response of the message
          if index != encoded.length - 1
            frg.id = CC.indigen_next_id
          else # last element
            frg.id = self.id
          end
          frg.content = content
          frg.send_to_server
        end
      end
    end # def send_to_server
  end # class ProtogenFromDevice

  # A simulated message that comes from a device.
  # @see CloudConnectServices::Presence
  class PresenceFromDevice < CCS::Presence

    # @param [String] type 'connect', 'reconnect' or 'disconnect'
    # @param [String] reason reason for the event
    # @param asset (see TestsHelper::MessageFromDevice#initialize)
    # @param account (see TestsHelper::MessageFromDevice#initialize)
    # @param time [String] timestamp of the event
    def initialize(type = 'connect', reason = 'closed_by_server', asset = "123456789", account = 'tests', time = nil)
      time = Time.now.to_i if time.nil?
      super('meta' => {'account' => account},
        'payload' => {
          'type' => 'presence',
          'time' => time,
          'bs' => "b3_4200",
          'type' => type,
          'reason' => reason,
          'account' => account
        })
    end

    # Send this presence to the server.
    def send_to_server
       `curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '#{self.to_hash.to_json}' http://localhost:5001/presence`
    end
  end

  # Simulated track data from a device.
  # @see CloudConnectServices::Track
  class TrackFromDevice < CCS::Track

    # @param data track data
    # @param id message ID
    # @param asset (see TestsHelper::MessageFromDevice#initialize)
    # @param account (see TestsHelper::MessageFromDevice#initialize)
    def initialize(data, id = "1234", account="tests", asset="123456789")
      super('meta' => {'account' => account},
        'payload' => {
          'data' => data,
          'id' => id,
          'asset' => asset
        })
    end

    # Send this track to the server.
    def send_to_server
      `curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '#{self.to_hash.to_json}' http://localhost:5001/track`
    end

  end

  # @!endgroup

end
