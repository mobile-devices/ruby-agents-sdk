# Provides several utilities to write unit tests inside the SDK
require_relative "../API/cloud_connect_services"
require_relative "../API/cloud_connect_services_internal"
require_relative "cloud_gate"
require 'base64'
require 'json'

# WARNING: to port this to Ragent, you must set the hooks correctly

module TestsHelper

  # helper to help testing asynchronous behaviour (imte in seconds)
  # Usage:
  # wait_for { a.should == b }
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

  @@messages = RingBuffer.new(100)
  @@device_msg = RingBuffer.new(100)
  # mappings allows us to know which id was associated to a given tempId
  @@mappings = {}

  # callback called everytime a message is sent
  def self.message_sent(msg)
    @@messages << msg
  end

  # callback called evrytime an ack is pushed to the device
  def self.id_generated(id, tempId)
    # quick but dirty (and buggy) way to avoid running out of memory
    if @@mappings.length > 100
      @@mappings = {}
    end
    @@mappings[tempId] = id
  end

  def self.incoming_message(msg)
    @@device_msg << msg
  end

  # wait for a server response to a given device message
  # - number_of_responses is either nil (wait until timeout and return all responses)
  # or a an integer (return as soon as number_of_responses response were encountered)
  # - the method will return after 'timeout' seconds either way
  # and will return an array of response messages (can be empty)
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

  # return the next messages sent by a device with the given asset
  # tiemout and number_of_messages follow the same rules as in wait_for_responses
  # type determines the type of message to accept
  # note: will also trigger on messages created from the code and sent with send_to_server (see below)
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

  # A message that comes from a device
  # Enables simulating interaction with a device
  class MessageFromDevice < CCS::Message

    ##
    # asset: IMEI of the (simulated) device
    # account: account name to use
    # content: string with the content of the message
    # channel: the name of the communication channel
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

    # send the message to the server
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

  class PresenceFromDevice < CCS::Presence
    def initialize(type = 'connect', reason = 'closed_by_server', asset = "123456789", account = 'tests', time = nil)
      time = Time.now.to_f if time.nil?
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

    def send_to_server
      handle_msg_from_device('presence', self.to_hash)
    end
  end

  class TrackFromDevice < CCS::Track

    def initialize(data, id = "1234", account="tests", asset="123456789")
      super('meta' => {'account' => account},
        'payload' => {
          'data' => data,
          'id' => id,
          'asset' => asset
        })
    end

    def send_to_server
      handle_msg_from_device('track', self.to_hash)
    end

  end

end

# register the test helper
CloudGate.add_observer(TestsHelper)