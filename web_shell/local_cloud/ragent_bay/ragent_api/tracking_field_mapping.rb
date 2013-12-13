#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module RagentApi
  module TrackFieldMapping

    def self.invalid_map
      @mapping_track_field_number = nil
    end

    def self.fetch_default_map
      @default_track_field_info ||= begin
        path = File.expand_path("..", __FILE__)
        YAML::load(File.read("#{path}/default_tracks_field_info.json"))
      end
    end


    def self.fetch_map(account)
      #Because we only have a static file, we will always use default account
      account = 'default'

      @mapping_track_field_number ||= begin
        # set default map
        {'default' =>  self.fetch_default_map}
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
    def self.get_by_id(int_id, account, no_error = 'false')
      if RAGENT.running_env_name == 'sdk-vm'
        account = 'default'
      end
      self.fetch_map(account).each do |field|
        if "#{field['field']}" == "#{int_id}"
          return field
        end
      end
      if !no_error
        raise "Field '#{int_id}' not found on account '#{account}'."
      end
    end

    def self.get_by_name(str_name, account, no_error = 'false')
      if RAGENT.running_env_name == 'sdk-vm'
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
end
