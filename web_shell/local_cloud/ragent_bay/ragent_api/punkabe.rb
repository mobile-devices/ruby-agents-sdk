#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module PUNK
  def self.start(id, action="...")
    if RAGENT.running_env_name == 'sdk-vm'
      CC.logger.info("PUNKabeNK_#{id}_#{action}")
    end
  end

  def self.drop(id)
    if RAGENT.running_env_name == 'sdk-vm'
      CC.logger.info("PUNKabeDROP_#{id}")
    end
  end

  def self.end(id, type, way, title)
    if RAGENT.running_env_name == 'sdk-vm'
      CC.logger.info("PUNKabe_#{id}_axd_{\"type\":\"#{type}\", \"way\":\"#{way}\", \"title\":\"#{title}\"}")
    end
  end
end
