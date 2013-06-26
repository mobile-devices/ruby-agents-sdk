#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################



module CloudConnectServices


  #============================== CLASSES ========================================

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

        self.parent_id = nil
        self.thread_id = nil
        self.asset = nil
        self.sender = '@@server@@'
        self.recipient = nil
        self.type = 'message'
        self.recorded_at = 007
        self.received_at = 007

        #todo : marche pas tel quel
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

        if self.type != 'message'
          raise "Message: wrong type of message : '#{type}'"
          return
        end

        if self.id.blank?
          self.id = CC.indigen_next_id
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

    def fast_push()
      CC.push(self.to_hash)
    end

    def push(asset, account)
        # set asset
        self.asset = asset
        self.recipient = asset

        # set acount is meta
        self.meta['account'] = account

        # Protogen encode
        if defined? ProtogenAPIs
          begin
            decoded = ProtogenAPIs.encode(self)

            if decoded.is_a? String
              self.content = decoded
              CC.logger.info("Protogen content is simple string")
            elsif decoded.is_a? Array
              CC.logger.info("Protogen content is an array of size #{decoded.size}")
              self.content = decoded[-1]
              # remove last fragment from list
              decoded.slice!(-1)
              # let create X fragment
              decoded.each { |content|
                frg = self.clone
                frg.id = CC.indigen_next_id
                frg.content = content
                frg.fast_push
              }
            else
              raise "message push protogen unknown decoded type : #{decoded.type}"
            end

          rescue Protogen::UnknownMessageType => e
            if $allow_non_protogen
              CC.logger.warn("CloudConnectServices:Messages.push: unknown protogen message type: #{e.inspect}")
            else
              raise e
            end
          end
        else
          if $allow_non_protogen
            CC.logger.warn('CloudConnectServices:Messages.push: ProtogenAPIs not defined')
          else
            raise "No Protogen defined"
          end
        end

        self.fast_push
    end

    def reply_content(content, cookies)
      msg = self.clone # todo : check si on clone bien récursivement les table de hash
      msg.parent_id = self.id
      msg.id = CC.indigen_next_id
      msg.content = content
      msg.meta['protogen_cookies'] = cookies
      msg.push(self.asset, self.account)
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


  class Log

    def initialize(header_txt)
      @head = header_txt
    end

    def debug(str_msg)
      CC.logger.debug("#{@head}#{str_msg}")
    end

    def info(str_msg)
      CC.logger.info("#{@head}#{str_msg}")
    end

    def warn(str_msg)
      CC.logger.warn("#{@head}#{str_msg}")
    end

    def error(str_msg)
      CC.logger.error("#{@head}#{str_msg}")
    end

  end



  #============================== METHODS ========================================

  def self.print_ruby_exeption(e)
    stack=""
    e.backtrace.take(20).each { |trace|
      stack+="  >> #{trace}\n"
    }
    CC.logger.error("  RUBY EXCEPTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n >> #{e.inspect}\n\n#{stack}\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
  end


end


CCS = CloudConnectServices