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
      'err_parse' => [0,0,0],
      'err_dyn_channel' => [0,0,0],
      'err_while_send_ack' => [0,0,0]
      },
      'default_agent' =>  {
        'received' => [0,0,0],
        'err_while_process' => [0,0,0]
      },
      'agents' => {}
    }

    get_run_agents.each { |agent|
      @daemon_stat['agents'][agent] = {
        'received' => [0,0,0],
        'err_while_process' => [0,0,0]
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