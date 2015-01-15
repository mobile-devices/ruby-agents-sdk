module TrackCache

  @track_map = {}

  def self.value
    @track_map
  end


  # return track with all previous fields in it
  def self.inject_cache(track)
    user_api.mdi.tools.log.debug("fetch map from cache (#{@track_map.class}): #{@track_map}")


    key = track.asset
    # save it
    track.fields_data.each do |field|
      @track_map["#{field['name']}|recorded_at"] = field['recorded_at']
      @track_map["#{field['name']}|raw_value"] = field['raw_value']
    end
    # say it
    user_api.mdi.tools.log.debug("fetch map from cache (#{@track_map.class}): #{@track_map}")

    # set everything in meta (map is a hash?)
    track.meta['fields_cached'] = @track_map.clone

    track
  end





end # module LimitedApis