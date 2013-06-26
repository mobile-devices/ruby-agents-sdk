#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module CloudConnectServicesInternal

  def redis()
    @redis ||= Redis::Namespace.new('CCSI', :redis => CCS.redis)
  end

end

CCSI = CloudConnectServicesInternal