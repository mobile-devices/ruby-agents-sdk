#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module CloudConnectServicesInternal

  #============================== CLASSES ========================================


  #============================== METHODS ========================================

  def self.redis()
    @redis ||= Redis::Namespace.new('CCSI', :redis => CC.redis)
  end

  def self.redis_shared()
    @redis ||= Redis::Namespace.new("CCSI", :redis => CC.redis)
  end

end

CCSI = CloudConnectServicesInternal