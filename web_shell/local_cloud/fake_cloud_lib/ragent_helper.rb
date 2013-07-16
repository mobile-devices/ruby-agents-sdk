#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module RagentHelper

  #============================== CLASSES ========================================


  #============================== METHODS ========================================


  def self.generated_path()
    #todo: maybe put it here instead ?
    generated_rb_path
  end

  def self.running_agents()
    @rh_running_agents ||= begin
      if File.exists?("#{RH.generated_path}/running_agents")
        running = File.read("#{RH.generated_path}/running_agents")
        running.split('|')
      else
        []
      end
    end
  end

end

RH = RagentHelper