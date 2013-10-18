#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

# @api private
module CloudConnectServicesInternal

  #============================== CLASSES ========================================

  # @api private
  class ClassSubscriber < Struct.new(:classes)
    def initialize
      self.classes = []
    end
    def subscribe(user_class)
      self.classes << user_class
    end
    def get_subscribers
      self.classes
    end
  end

  # @api private
  class CloudWork < Struct.new(:id, :message, :env)

    def initialize(message)
      self.id = CC.indigen_next_id
      self.message = message
      # Presence Message and Track have an 'account' attribute, but not Order
      if message.respond_to? :account
        account = message.account
      else
        account = nil
      end
      self.env = {
        :account => account
      }
    end

    def work_account
      self.env[:account]
    end

    def run
      case "#{self.message.class}"
      when 'CloudConnectServices::Presence'
        CCSI.user_class_presence_subscriber.get_subscribers.each do |user_class|
          user_class.handle_presence(self.message)
        end
      when 'CloudConnectServices::Message'
        CCSI.user_class_message_subscriber.get_subscribers.each do |user_class|
          user_class.handle_message(self.message)
        end
      when 'CloudConnectServices::Track'
        CCSI.user_class_track_subscriber.get_subscribers.each do |user_class|
          CC.logger.info("Doing class #{user_class}")
          user_class.handle_track(self.message)
        end
      when 'CloudConnectServices::Order'
        CCSI.user_class_subscriber.get_subscribers.each do |user_class|
          if self.message.agent == user_class.agent_name
            user_class.handle_order(self.message)
          end
        end
      else
        CC.logger.error("Unmanaged class #{self.message.class}")
      end # case
    end # run
  end


  # @api private
  class TrackFieldMapping
    def invalid_map
      @mapping_track_field_number = nil
    end

    def fetch_default_map
      @default_track_field_info ||= begin
        path = File.expand_path("..", __FILE__)
        YAML::load(File.open("#{path}/default_tracks_field_info.json"))
      end
    end


    def fetch_map(account)
      #Because we only have a static file, we will always use default account
      account = 'default'

      @mapping_track_field_number ||= begin
        # set default map
        {'default' =>  fetch_default_map}
      end

      if @mapping_track_field_number.has_key?(account)
        @mapping_track_field_number[account]
      else
        # todo fetch from cloud api, but for now, we raise
        raise "Account '#{account}' not available."
      end
    end

    # fields look like :
    # {
    #     "name": "GPRMC_VALID",
    #     "field": 3,
    #     "field_type": "string",
    #     "size": 1,
    #     "ack": 1
    # }

    # return a field struct
    def get_by_id(int_id, account, no_error = 'false')
      if $ENV_TARGET == 'sdk-vm'
        account = 'default'
      end
      fetch_map(account).each do |field|
        if "#{field['field']}" == "#{int_id}"
          return field
        end
      end
      if !no_error
        raise "Field '#{int_id}' not found on account '#{account}'."
      end
    end

    def get_by_name(str_name, account, no_error = 'false')
      if $ENV_TARGET == 'sdk-vm'
        account = 'default'
      end
      fetch_map(account).each do |field|
        if "#{field['name']}" == "#{str_name}"
          return field
        end
      end
      if !no_error
        raise "Field '#{str_name}' not found on account '#{account}'."
      end
    end

  end

  #============================== METHODS ========================================

  def self.redis
    @redis ||= Redis::Namespace.new('CCSI', :redis => CC.redis)
  end

  def self.track_mapping
    @track_mapping ||= TrackFieldMapping.new
  end

  def self.user_class_subscriber
    @user_class_subscriber ||= ClassSubscriber.new
  end

  def self.user_class_presence_subscriber
    @user_class_presence_subscriber ||= ClassSubscriber.new
  end

  def self.user_class_message_subscriber
    @user_class_message_subscriber ||= ClassSubscriber.new
  end

  def self.user_class_track_subscriber
    @user_class_track_subscriber ||= ClassSubscriber.new
  end

end

CCSI = CloudConnectServicesInternal