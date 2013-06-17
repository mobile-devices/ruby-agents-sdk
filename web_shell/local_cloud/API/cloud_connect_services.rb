#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


def print_ruby_exeption(e)
  stack=""
  e.backtrace.take(20).each { |trace|
    stack+="  >> #{trace}\n"
  }
  CC.logger.error("  RUBY EXCEPTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n >> #{e.inspect}\n\n#{stack}\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
end


module CloudConnectServices
  class Presence < Struct.new(:asset, :time, :bs, :type, :reason, :account, :meta)

    # With :

    # "meta", a map with some meta data, generally none.

    # "payload", a map with :
    #   asset : imei of the device
    #   time : timestamp of the event
    #   bs : binary server source
    #   type : 'connect' or 'reconnect' or 'disconnect'
    #   reason : reason for the event

    # "account" (account name type String).

    def initialize(struct)
      self.meta = struct['meta']
      payload = struct['payload']
      self.asset = payload['asset']
      self.time = payload['time']
      self.bs = payload['bs']
      self.type = payload['type']
      self.reason = payload['reason']
      self.account = meta['account']

      if type != 'connect' && type != 'reconnect' && type != 'disconnect'
        raise "Wrong type of presence : #{type}"
      end
    end

    def to_hash
      r_hash = {}
      r_hash['meta'] = self.meta
      r_hash['payload'] = {
        'asset' => self.asset,
        'time' => self.time,
        'bs' => self.bs,
        'type' => self.type,
        'reason' => self.reason,
        'account' => self.account
      }
      r_hash.delete_if { |k, v| v.nil? }
    end

  end

  class Message < Struct.new(:id, :parent_id, :thread_id, :asset, :sender, :recipient, :type, :recorded_at, :received_at, :channel,:account, :meta, :content)

    # "meta", a map with some meta data, generally none.

    # "payload", a map with :
    #   id : tmp id from the device
    #   asset : imei of device
    #   sender : Sender identifier (can be the same as the asset)
    #   recipient : Recipient identifier (can be the same as the asset)
    #   type : 'message'
    #   recorded_at : timestamp
    #   received_at : timestamp
    #   channel : string channel
    #   payload : content

    # "account" (account name type String).

    def initialize(struct = nil)
      if struct.blank?
        self.meta = {}
        self.id = CC.indigen_next_id
        self.parent_id = nil
        self.thread_id = nil
        self.asset = nil
        self.sender = '@@server@@'
        self.recipient = nil
        self.type = 'message'
        self.recorded_at = 007
        self.received_at = 007

        if @CHANNEL && @CHANNEL[0]
          self.channel = @CHANNEL[0]
        else
          self.channel = nil
        end

        self.content = nil

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
        self.received_at = struct['received_at']
        self.channel = payload['channel']

        if meta.is_a? Hash
          self.account = meta['account']
        end

        if type != 'message'
          raise "Message: wrong type of message : '#{type}'"
          return
        end
        if self.id == nil
          raise "Message: id is empty"
          return
        end
      end

    end

    # to do :
    # to_hash
    # push
    # reply(Message)
    # content
    def to_hash
      r_hash = {}
      r_hash['meta'] = self.meta
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
      r_hash.delete_if { |k, v| v.nil? }
    end

    def push(asset, account)
      begin
        # set asset
        self.asset = asset
        self.recipient = asset

        # set acount is meta
        self.meta['account'] = account

        CC.push(self.to_hash)

        if self.meta['is_reply']
          SDK_STATS.stats['agents']["#{@AGENT_NAME}"]['reply_sent_to_device'] += 1
        else
          SDK_STATS.stats['agents']["#{@AGENT_NAME}"]['push_sent_to_device'] += 1
        end
        SDK_STATS.stats['agents']["#{@AGENT_NAME}"]['total_sent'] += 1
      rescue Exception => e
        CC.logger.error("Error on push with reply=#{@is_reply}")
        print_ruby_exeption(e)
        if self.meta['is_reply']
          SDK_STATS.stats['agents']["#{@AGENT_NAME}"]['err_on_reply'] += 1
        else
          SDK_STATS.stats['agents']["#{@AGENT_NAME}"]['err_on_push'] += 1
        end
        SDK_STATS.stats['agents']["#{@AGENT_NAME}"]['total_error'] += 1
      end
    end

    def reply_content(content)
      msg = self.clone
      msg.parent_id = self.id
      msg.id = CC.indigen_next_id
      msg.content = content

      msg.meta['is_reply'] = true
      msg.push(this.asset, this.account)
      msg.meta['is_reply'] = nil
    end

  end

  class Track < Struct.new(:id, :asset, :data, :account, :meta)

    # "meta", a map with some meta data, generally none.

    # "payload", a map with :
    #    id : tmp id from the device
    #    asset : imei of device
    #    data map, with :
    #    latitude
    #    longitude
    #    recorded_at
    #    received_at
    #    field1
    #    field2
    #    ...

    # "account" (account name type String).

    def initialize(struct)
      self.id = struct['id']
      self.asset = struct['asset']
      self.data = struct['data']
      self.meta = struct['meta']
      self.account = self.meta['account']
    end

    def to_hash
      r_hash = {}
      r_hash['meta'] = self.meta
      r_hash['payload'] = {
        'id' => self.id,
        'asset' => self.asset,
        'data' => self.sender
      }
      r_hash.delete_if { |k, v| v.nil? }
    end
  end


  class AgentNotFound < StandardError
  end

  class Order < Struct.new(:agent, :code, :params)

    def initialize(struct)
      self.agent = struct['agent']
      self.code = struct['order']
      self.params = struct['params']

      #todo: test nullity or agent and order?

      if !(agents_running.include?(self.agent))
        raise AgentNotFound , "Server: agent #{self.agent} is not running on this bay"
      end
    end

    def to_hash
      r_hash = {}
      r_hash['agent'] = self.agent
      r_hash['order'] = self.order
      r_hash['params'] = self.params
      r_hash.delete_if { |k, v| v.nil? }
    end
  end

end


CCS = CloudConnectServices