#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module UserApis
  module Mdi
    module Dialog
      # A class that represents a standard message. Used in the DeviceGate and CloudGate APIs for instance.
      class MessageClass < Struct.new(:id, :parent_id, :thread_id, :asset, :sender, :recipient, :type, :recorded_at, :received_at, :channel, :account, :meta, :content, :cookies)

        def initialize(apis, struct = nil)

          @user_apis = apis

          if struct.blank?
            self.meta = {}
            self.type = 'message'
          else

            self.meta = struct['meta']
            payload = struct['payload']

            self.content = payload['payload']
            self.id = payload['id']
            self.parent_id = payload['parent_id']
            self.thread_id = payload['thread_id']
            self.asset = payload['asset']
            self.sender = payload['sender']
            self.recipient = payload['recipient']
            self.type = payload['type']
            self.recorded_at = payload['recorded_at']
            self.received_at = payload['received_at']
            self.channel = payload['channel']

            if meta.is_a? Hash
              self.account = meta['account']
              self.cookies = meta['protogen_cookies']
            end

            if self.type != 'message' && self.type != 'ack'
              raise "Message: wrong type of message : '#{type}'"
              return
            end

            if self.id.blank?
              self.id = CC.indigen_next_id(self.asset)
            end

          end

        end

        def user_api
          @user_apis
        end


        # Hash representation of a message.
        #
        #   ``` ruby
        #   {'meta' => self.meta,
        #   'payload' => {
        #     'payload' => self.content,
        #     'channel' => self.channel,
        #     'parent_id' => self.parent_id,
        #     'thread_id' => self.thread_id,
        #     'id' => self.id,
        #     'asset' => self.asset,
        #     'sender' => self.sender,
        #     'recipient' => self.recipient,
        #     'type' => self.type,
        #     'recorded_at' =>  self.recorded_at,
        #     'received_at' =>  self.received_at,
        #     'channel' =>  self.channel
        #   }
        #   ```
        #
        # @return [Hash] a hash representing this message.
        # @api private
        def to_hash
          r_hash = {}
          r_hash['meta'] = self.meta
          r_hash['meta'] = {} if r_hash['meta'] == nil
          r_hash['meta']['account'] = self.account
          r_hash['payload'] = {
            'payload' => self.content,
            'channel' => self.channel,
            'parent_id' => self.parent_id,
            'thread_id' => self.thread_id,
            'id' => self.id,
            'asset' => self.asset,
            'sender' => self.sender,
            'recipient' => self.recipient,
            'type' => self.type,
            'recorded_at' =>  self.recorded_at,
            'received_at' =>  self.received_at,
            'channel' =>  self.channel
          }
          r_hash['meta'].delete_if { |k, v| v.nil? }
          r_hash['payload'].delete_if { |k, v| v.nil? }
          r_hash
        end

        # Pushes the message to the device without any preliminary setup.
        # Useful if you want to do all the setup yourself.
        # @api private
        def fast_push
          CC.push(self.to_hash)
        end

        # Sends this message to the device, using the current message configuration.
        #
        # It will not do any Protogen-related stuff before sending the message.
        #
        # This method will set the `received_at` field to `Time.now.to_i`. Will also set the sender to `@@server@@` if not exists.
        #
        # If the method parameters are not defined the current values stored in the message will be used.
        #
        # @param [String] asset the IMEI of the device or other similar unique identifier.
        # @param [Account] account the account name to use.
        # @api private
        def push(asset = nil, account = nil)
          if !(self.content.is_a? String)
            raise "message content must be of type String (got #{self.content.class.name})"
          end

          # set asset unless nil
          self.asset = asset unless asset.nil?
          self.recipient = asset unless asset.nil?

          # set acount unless nil
          self.account = account unless account.nil?

          # set sender if not defined (ie a direct push)
          self.sender ||= '@@server@@'

          # set received_at
          self.received_at = Time.now.to_i

          self.fast_push
        end


      end #Message
    end #Dialog
  end #Mdi
end #UserApis
