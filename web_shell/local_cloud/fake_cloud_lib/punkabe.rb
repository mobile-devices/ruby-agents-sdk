#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module PUNK
  def self.start(id, action="...")
    CC.logger.info("PUNKabeNK_#{id}_#{action}")
  end

  def self.end(id, type, way, title)
    CC.logger.info("PUNKabe_#{id}_axd_{\"type\":\"#{type}\", \"way\":\"#{way}\", \"title\":\"#{title}\"}")
  end
end
