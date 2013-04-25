require 'hashie'

class Message < Hashie::Mash
  class << self
    alias :from :new
  end

  def initialize(source_hash = nil, default = nil, &blk)
    super(source_hash, default, &blk)
    set_defaults!
  end

  def reply(payload = nil)
    self.class.new do |r|
      r.channel = self.channel
      r.parent_id = self.id
      r.asset = self.asset
      r.recipient = self.sender
      r.sender = self.recipient
      r.type = self.type
      r.thread_id = self.thread_id
      r.payload = payload unless payload.blank?
      r.id = ID_GEN.next_id()
    end
  end

#todo: un push pour VMdev qui attaque en local, et un push prod qui utilise les API

  def push(meta = {}, queue = "bs_msg_in")
    self.validate!

    # push to local
    push_someting_to_device(self)

    # push to api web (todo)


    #Rqueue mode : to remove in vm
    #DaemonKit.logger.info "posting #{self.to_hash.inspect} to #{queue}"
    #msg = { meta: meta, payload: self }
    #CloudConnect.rqueue.set queue, msg
  end

  def valid?
    @errors = []
    @errors << "Id must be set" unless self.id
    @errors << "Asset or Recipient must be set" unless self.asset && self.recipient
    @errors << "Channel must be set" unless self.channel
    @errors.empty?
  end

  def errors
    valid?
    @errors
  end

  protected
    def set_defaults!
      self.id ||= ID_GEN.next_id(self.asset)
      self.sender ||= '@@server@@'
      if self.asset
        self.recipient ||= self.asset
      else
        self.asset ||= self.recipient
      end
      self.type ||= :message
    end

    def validate!
      self.set_defaults!
      if !self.valid?
        raise self.errors.join(', ') if !self.errors.blank?
      else
        self
      end
    end
end
