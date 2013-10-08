#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module CloudConnectServicesInternal

  #============================== CLASSES ========================================

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
      if $ENV_TARGET = 'sdk-vm'
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
      if $ENV_TARGET = 'sdk-vm'
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

end

CCSI = CloudConnectServicesInternal