#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module CloudConnectServicesInternal

  #============================== CLASSES ========================================

  # @api private
  class TrackFieldMapping
    def invalud_map
      @mapping_track_field_number = nil
    end

    def fetch_map
      @mapping_track_field_number ||= begin
        # todo fetch from cloud api
        Math.sqrt(-1)
        {}
      rescue Exception => e
        # if fail, fetch from default file
        path = File.expand_path("..", __FILE__)
        YAML::load(File.open("#{path}/mapping_track_field_number.yml"))
      end
     end

     def int_value_of(str_name)
      fetch_map.each do |k,v|
        if v == str_name
          return k
        end
      end
    end

    def str_value_of(int_name)
      fetch_map[int_name]
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