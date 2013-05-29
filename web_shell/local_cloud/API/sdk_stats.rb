#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module SDK_STATS

  #stats :
  class StatTypeSet < Struct.new(:presence, :msg, :track)
    def initialize(presence = 0, msg = 0, track = 0) # constructor
      super
    end
  end

  def reset_stats
    @daemon_stat = {
      'server' => {
        'total_received' => 0,
        'total_error' => 0,
        'total_sent' => 0,
        'received' => [0,0,0,0],
        'ack_sent_to_device' => [0,0,0,0],
        'err_parse' => [0,0,0,0],
        'err_dyn_channel' => [0,0,0,0],
        'err_while_send_ack' => [0,0,0,0],
        'in_queue' => 0,
        'total_ack_queued' => 0,
        'total_queued' => 0,
        'remote_call_unused' => 0
        },
        'default_agent' =>  {
          'total_received' => 0,
          'total_error' => 0,
          'total_sent' => 0,
          'received' => [0,0,0,0],
          'err_while_process' => [0,0,0,0],
          'reply_sent_to_device' => 0,
          'err_on_reply' => 0,
          'push_sent_to_device' => 0,
          'err_on_push' => 0
          },
        'agents' => {}
      }

    get_run_agents.each { |agent|
      @daemon_stat['agents'][agent] = {
        'total_received' => 0,
        'total_error' => 0,
        'total_sent' => 0,
        'received' => [0,0,0,0],
        'err_while_process' => [0,0,0,0],
        'reply_sent_to_device' => 0,
        'err_on_reply' => 0,
        'push_sent_to_device' => 0,
        'err_on_push' => 0
        }
      }
  end

  def stats
    @daemon_stat ||= begin
      reset_stats
      @daemon_stat
    end
  end



end