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
      'received' => [0,0,0],
      'ack_sent_to_device' => [0,0,0],
      'err_parse' => [0,0,0],
      'err_dyn_channel' => [0,0,0],
      'err_while_send_ack' => [0,0,0]
      },
      'default_agent' =>  {
        'received' => [0,0,0],
        'err_while_process' => [0,0,0],
        'reply_sent_to_device' => 0,
        'err_on_reply' => 0,
        'push_sent_to_device' => 0,
        'err_on_push' => 0
      },
      'agents' => {}
    }

    get_run_agents.each { |agent|
      @daemon_stat['agents'][agent] = {
        'received' => [0,0,0],
        'err_while_process' => [0,0,0],
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