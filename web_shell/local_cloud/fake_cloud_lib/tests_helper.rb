require_relative "../API/cloud_connect_services"
require_relative "../API/cloud_connect_services_internal"
require_relative "cloud_gate"
require 'base64'
require 'json'

# WARNING: to port this to Ragent, you must set the hooks correctly

# @api public
# Provides several utilities to write unit tests inside the SDK.
# @note Methods and classes of this module are intended to be used in automated tests only!
#   Do not use this module in your code otherwise, as its inner behaviour may differ between environments.
module TestsHelper

  # @!group Helper methods

  # Helper to test asynchronous behaviour.
  #
  # This method execute the given block at given time intervals until the block returns without raising an exception.
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
  #
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
  #   If a `Fixnum`, returns as soon as `number_of_responses` responses are sent.
  # @param [Fixnum] timeout this method will return after `timeout` seconds.
  # @return [Array<CloudConnectServices::Message>] messages sent by the server in response to the given message
  # @note Protogen messages are sent as multiple messages by the server.
  #   However, this method will consider all these small messages as a big one, so you don't have to worry
  #   about using Protogen or not.
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
  #   If a `Fixnum`, returns as soon as `number_of_messages` messages are sent.
  # @param timeout (see TestsHelper.wait_for_responses).
  # @param [Array] type class of messages to be retrieved.
  # @return [Array] messages sent by the device
  # @note Will also trigger on messages created from the code and sent with {TestsHelper::MessageFromDevice#send_to_server}.
  def self.wait_for_device_msg(asset, number_of_messages = 1, timeout = 5, type=[CCS::Message, CCS::Track, CCS::Presence])
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
      end
      value[1]
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

  # @!group Callbacks

  # @api private
  # Callback called everytime a message is sent.
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
      # so we encode it manually
      # the way it is done in push_something_to_device
      # all these methods are defined in cloud_gate.rb
      params['payload']['payload'] = Base64.encode64(params['payload']['payload'])
      handle_msg_from_device('message', params)
    end

  end

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
      handle_msg_from_device('presence', self.to_hash)
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
      handle_msg_from_device('track', self.to_hash)
    end

  end

  # @!endgroup

end

# register the test helper
CloudGate.add_observer(TestsHelper)