require 'json'

require_relative '../ragent_bay/user_api/user_api'

# @api public
# Provides several utilities to write unit tests inside the SDK.
# @note Methods and classes of this module are intended to be used in automated tests only!
#       Using them in your code will result in `NoMethodError`s on a production environment.
module TestsHelper

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
  # @api public
  def self.wait_for(time = 5, increment = 1, elapsed_time = 0, &block)
    yield
    rescue Exception
    if elapsed_time >= time
      raise $!, "#{$!} (waited for #{elapsed_time} seconds)", $!.backtrace
    else
      sleep increment
      wait_for(time, increment, elapsed_time + increment, &block)
    end
  end

  # Waits for server responses to a given device message and return these responses.
  # This is (obviously) a blocking call.
  # @param [UserApis::Mdi::Dialog::MessageClass] message the message sent by the device (using a temporary id)
  # @param [Fixnum, nil] number_of_responses if `nil`, wait until timeout and return all responses.
  #   If a `Fixnum`, return as soon as `number_of_responses` responses are sent.
  # @param [Fixnum] timeout this method will return after `timeout` seconds.
  # @return [Array<CloudConnectServices::Message>] messages sent by the server in response to the given message
  # @note Protogen messages are sent as multiple messages by the server.
  #   However, this method will consider all these small messages as a big one, so you don't have to worry
  #   about using Protogen or not.
  # @api public
  def self.wait_for_responses(message, number_of_responses = 1, timeout = 5)
    if !number_of_responses && number_of_responses <= 0
      raise ArgumentError.new("You must wait for at least 1 response message (given: #{number_of_responses})")
    end
    id_to_look_for = @@mappings[message.id]
    start_time = Time.now.to_f
    while Time.now.to_f - start_time < timeout
      res = @@messages.select { |msg| msg.parent_id == id_to_look_for }
      break if !number_of_responses && res.length >= number_of_responses
      sleep(0.1)
    end
    res
  end

  # Create a file for testing purposes. You can then access this file with the SDK file API.
  # The file_info attribute of the provided file must be correctly set.
  # Warning: the access rights management implemented in VM mode is a small subset of what is available in the Cloud.
  # but should suffice for testing purposes. When storing a file, the associated file_info role list is stored.
  # When calling {get_file}, this method will check is the provided
  # account or asset was present in the role list associated with this file.
  # This method is unvailable in Ragent mode.
  # @param [UserApis::Mdi::CloudFile] file file to store
  # @note will overwrite any previous file stored with the same name/namespace
  def self.create_file(file)
    if file.file_info.nil?
      raise ArgumentError.new("To create a file, you must provide a non-nil, valid file info object.")
    end
    path = CC::FileStorage.file_path(file.file_info.namespace, file.file_info.name)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.rm(path) if File.exist?(path)
    File.write(path, CC::FileStorage.file_to_json(file))
  end

  # Delete a file.
  # @param [String] namespace
  # @param [String] filename
  # @api public
  def self.delete_file(namespace, filename)
    CC::FileStorage.delete_file(namespace, filename)
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
      value = @data[key]
      if value
        renew(key)
        age_keys
        value[1]
      end
    end

    def inspect
      "Max cache size: #{max_size} ; data: #{@data.inspect}"
    end

    private

    def renew(key)
      @data[key][0] = 0
    end

    def delete_oldest
      m = @data.values.map { |v| v[0] }.max
      @data.reject! { |_k, v| v[0] == m }
    end

    def age_keys
      @data.each { |k, _v| @data[k][0] += 1 }
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
  # @param [UserApis::Mdi::Dialog::MessageClass] msg the outgoing message. This is the message as pushed by the user, before
  #        any Protogen stuff happens with the payload.
  def self.message_sent(msg)
    @@messages << msg
  end

  # @api private
  # Callback called everytime an ACK is pushed to the device.
  # @param [Fixnum] id the id generated by the server, corresponding to the device tempId
  # @param [Fixnum] tempId the temporary ID generated by the device.
  def self.id_generated(id, tempId)
    @@mappings[tempId] = id
  end

  # @!endgroup

  # @!group Events helper

  # A simulated message that comes from a device.
  # @api public
  class DeviceMessage

    # @param [String] asset IMEI or unique identifier of the (simulated) device
    # @param [String] account account name to use
    # @param [String] content string with the content of the message (Protogen objects are not accepted)
    # @param [String] channel the name of the communication channel
    def initialize(content, channel, asset = "123456789", account = "tests")
      @msg = user_api.mdi.dialog.create_new_message(
        'meta' => { "account" => account,
        'class'=> 'message' },
        'payload' => {
          'type' => 'message',
          'id' => '',
          'asset' => asset,
          'sender' => asset,
          'channel' =>  channel,
          'payload' => content
        },
        'account' => account
      )
    end

    # Send this message to the server.
    def send_to_server
      saved_api = user_api
      release_current_user_api
      params = @msg.to_hash
      # handle_message_from_device needs a base64 encoded content
      params['payload']['payload'] = Base64.encode64(params['payload']['payload'])
      `curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '#{params.to_json}' http://localhost:5001/message`
      set_current_user_api(saved_api)
    end

  end

  # Simulated presence from a device
  # @api public
  class DevicePresence

    # @param [String] type 'connect', 'reconnect' or 'disconnect'
    # @param [String] reason reason for the event
    # @param asset (see TestsHelper::DeviceMessage#initialize)
    # @param account (see TestsHelper::DeviceMessage#initialize)
    # @param [Integer] id the message ID. If nil, a suitable ID will be automatically generated.
    # @param time [String] timestamp of the event
    def initialize(type = 'connect', reason = 'closed_by_server', asset = "123456789", account = 'tests', time = nil, id = nil)
      time = Time.now.to_i if time.nil?
      id = CC.indigen_next_id if id.nil?
      @msg = user_api.mdi.dialog.create_new_presence(
        'meta' => { 'account' => account,
        'class' => 'presence'},
        'payload' => {
          'type' => 'presence',
          'time' => time,
          'bs' => "b3_4200",
          'type' => type,
          'reason' => reason,
          'account' => account,
          'asset' => asset,
          'id' => id
        })
    end

    # Send this presence to the server.
    def send_to_server
      saved_api = user_api
      release_current_user_api
      `curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '#{@msg.to_hash.to_json}' http://localhost:5001/presence`
      set_current_user_api(saved_api)
    end
  end

  # Simulated track data from a device.
  # @api public
  class DeviceTrack

    # Construct a new simulated track.
    # The payload of a track, represented as a hash, follows the following format:
    #
    # ```ruby
    # {
    #    "id" => "123456",
    #    "account" => "unstable",
    #    "longitude" =>  236607,
    #    "latitude" => 4878377,
    #    "recorded_at" => 1368449272,
    #    "received_at" => 1368449284,
    #    "28" => "123456",              # /* field_id  => field_value */
    #    "42" => "hello"
    # }
    #
    # ```
    #
    # @param [Hash] data track payload (see above)
    # @param asset (see TestsHelper::DeviceMessage#initialize)
    # @param account (see TestsHelper::DeviceMessage#initialize)
    def initialize(data, account = "tests", asset = "123456789")
      @msg =  user_api.mdi.dialog.create_new_track(
        "meta" => { "account" => account,
        "class" => 'track' },
        "payload" => data,
        "asset" => asset
        )
    end

    # Send this track to the server.
    def send_to_server
      saved_api = user_api
      release_current_user_api
      `curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '#{@msg.to_hash.to_json}' http://localhost:5001/track`
      set_current_user_api(saved_api)
    end

  end

  # A message posted on an arbitrary queue.
  # @api public
  class QueueMessage

    # @param [Hash] params the message to post on the queue (should define at least the keys "meta" and "payload")
    # @param [String] queue_name the queue to post on (complete queue name: "parent:child")
    def initialize(params, queue_name)
      @params = params
      @queue_name = queue_name
    end

    # Post on a shared queue.
    def post_as_shared
      saved_api = user_api
      release_current_user_api
      body = { "data" => @params, "queue" => @queue_name }
      `curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '#{body.to_json}' http://localhost:5001/other_queue`
      set_current_user_api(saved_api)
    end

    # Post on a broadcast queue. The actual queue name will be automatically adjusted to include the runtime ID.
    def post_as_broadcast
      saved_api = user_api
      release_current_user_api
      body = { "data" => @params, "queue" => @queue_name + "_" + RAGENT.runtime_id_code }
      `curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '#{body.to_json}' http://localhost:5001/other_queue`
      set_current_user_api(saved_api)
    end

  end

  # @!endgroup

end