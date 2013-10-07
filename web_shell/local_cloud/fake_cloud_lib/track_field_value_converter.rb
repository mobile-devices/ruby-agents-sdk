#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module TrackFieldValueConverter

  def self.convert_to_binary(value, type, size)

    converted_val = case field['type']
    when 'unknown'
      SDK.API.log.warn("convert_value_to_binary unknown format, might be rejected by rqueue")
      val
    when 'boolean'
      raise "boolean not yet implemented for tracking. sorry."
    when 'integer'
      raise "integer not yet implemented for tracking. sorry."
    when 'decimal'
      raise "decimal not yet implemented for tracking. sorry."
    when 'string'
      val
    when 'base64'
      raise "base64 not yet implemented for tracking. sorry."
    when nil
      raise "Bad configuration for field #{field_associed}: #{field}"
    else
      raise "Unmanaged convertion for field #{field_associed}: #{field}"
    end

    # in fake mode, keep it decoded
    value
  end


end
