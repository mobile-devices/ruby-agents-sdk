#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module SDK_STATS

  def self.reset_stats
    @daemon_stat = {
      'server' => {
        'uptime' => '-1',
        'start_time' => 'never',
        'total_received' => 0,
        'total_error' => 0,
        'internal_error' => 0,
        'total_sent' => 0,
        'received' => [0,0,0,0],
        'pulled_from_queue' => [0,0,0,0],
        'ack_sent_to_device' => [0,0,0,0],
        'err_parse' => [0,0,0,0],
        'err_dyn_channel' => [0,0,0,0],
        'err_while_send_ack' => [0,0,0,0],
        'in_queue' => 0,
        'total_ack_queued' => 0,
        'total_queued' => 0,
        'remote_call_unused' => 0
        },
        'agents' => {}
      }
    RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
      agent_name = user_agent_class.agent_name
      @daemon_stat['agents'][agent_name] = {
        'total_received' => 0,
        'total_error' => 0,
        'total_sent' => 0,
        'received' => [0,0,0,0],
        'err_while_process' => [0,0,0,0],
        'reply_sent_to_device' => 0,
        'err_on_reply' => 0,
        'push_sent_to_device' => 0,
        'err_on_push' => 0,
        'inject_to_cloud' => 0,
        'err_on_inject' => 0,
        'upstream_data' => [0,0,0,0],
        'downstream_data' => [0,0,0,0],
        'process_time' => [0.0,0.0,0.0,0.0]
      }
    end
  end

  # stat per type of protogen message

  def self.count_agents_internal_error
    count = 0
    RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
      @daemon_stat['agents'][user_agent_class.agent_name]['err_while_process'].each do |err|
        count += err
      end
    end
    count
  end

  def self.count_agents_received
    result = [0,0,0,0]
    RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
      result =  result.zip(@daemon_stat['agents'][user_agent_class.agent_name]['received']).map{ |x,y| x + y }
    end
    result
  end

  def self.count_agents_push
    count = 0
    RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
      count += @daemon_stat['agents'][user_agent_class.agent_name]['push_sent_to_device']
    end
    count
  end

    def self.count_agents_reply
    count = 0
    RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
      count += @daemon_stat['agents'][user_agent_class.agent_name]['reply_sent_to_device']
    end
    count
  end



  def self.stats
    @daemon_stat ||= begin
      reset_stats
      @daemon_stat
    end
  end


#todo: add all + helpers
end
