# Provides several utilities to write unit tests inside the SDK
require_relative "../API/cloud_connect_services"
require_relative "../API/cloud_connect_services_internal"
require_relative "cloud_gate"
require 'base64'
require 'json'

module TestsHelper

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

  @@messages = RingBuffer.new(30)
  # mappings allows us to know which id was associated to a given tempId
  @@mappings = {}

  # callback called everytime a message is sent
  def self.message_sent(msg)
    @@messages << msg
  end

  # callback called evrytime an ack is pushed to the device
  def self.id_generated(id, tempId)
    if @@mappings.length > 500
      @@mappings = {}
    end
    @@mappings[tempId] = id
  end

  # timeout in seconds
  def self.wait_for_response(message, timeout = 5)
    id_to_look_for = @@mappings[message.id]
    start_time = Time.now.to_f
    while Time.now.to_f - start_time < timeout
      res = @@messages.select{ |msg| (msg["payload"]["parent_id"] == id_to_look_for && msg["payload"]["type"] == "message") }.first
      break if res
      sleep(0.1)
    end
    return nil unless res
    res["payload"]["payload"] = Base64.decode64(res["payload"]["payload"])
    return CCS::Message.new(res)
  end

  # A message that comes from a device
  # Enables simulating interaction with a device
  class MessageFromDevice < CCS::Message

    ##
    # asset: IMEI of the (simulated) device
    # account: account name to use
    # content: string with the content of the message
    # channel: the name of the communication channel
    def initialize(asset, account, content, channel)
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
    def send_to_server()
      params = self.to_hash
      # handle_message_from_device needs a base64 encoded content
      # so we encode it manually
      # the way it is done in push_something_to_device
      # all these methods are defined in cloud_gate.rb
      params['payload']['payload'] = Base64.encode64(params['payload']['payload'])
      handle_msg_from_device('message', params)
    end

  end

end

# register the test helper
CloudGate.add_observer(TestsHelper)