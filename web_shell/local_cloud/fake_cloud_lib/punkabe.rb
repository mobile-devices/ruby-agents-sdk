#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module PUNK
  def start(id)
    CC.logger.info("PUNKabeNK_#{id}")
  end

  def end(id, type, way, title)
    CC.logger.info("PUNKabe_#{id}_axd_{\"type\":\"#{type}\", \"way\":\"#{way}\", \"title\":\"#{title}\"}")
  end
end
