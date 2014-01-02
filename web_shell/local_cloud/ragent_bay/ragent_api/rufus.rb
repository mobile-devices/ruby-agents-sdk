#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'rubygems'
require 'rufus/scheduler'
require json

module Rufus


  def self.run

    scheduler = Rufus::Scheduler.start_new

    crons = RAGENT.cron_tasks_to_map
    crons.each do |cron|
      scheduler.cron cron.cron_schedule do
        RIM.handle_order(JSON.parse(cron.order))
      end
    end

    # now wait and work
    #scheduler.join
  end

end
