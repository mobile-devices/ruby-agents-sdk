#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require_relative 'incoming_messages_handler'
require_relative 'tracking_field_mapping'
require_relative 'user_agent_class'
require_relative 'sdk_stats'

# cloud connect

require 'securerandom'


module RagentApi

  def self.api
    @ragent_api ||= begin
      env = {
        'root' => 'yes',
        'owner' => 'ragent',
        'agent_name' => 'ragent'
      }
      USER_API_FACTORY.gen_user_api(self, env)
    end
  end

  def self.track_mapping
    @track_mapping ||= TrackFieldMapping.new
  end

  def self.user_class_subscriber
    @user_class_subscriber ||= self.api.mdi.tools.create_new_subscriber
  end

  def self.user_class_presence_subscriber
    @user_class_presence_subscriber ||= self.api.mdi.tools.create_new_subscriber
  end

  def self.user_class_message_subscriber
    @user_class_message_subscriber ||= self.api.mdi.tools.create_new_subscriber
  end

  def self.user_class_track_subscriber
    @user_class_track_subscriber ||= self.api.mdi.tools.create_new_subscriber
  end

  def self.agents_project_src_path
    @agents_project_src_path ||= begin
      path = File.expand_path("..", __FILE__)
      File.expand_path("#{path}/../agents_project_source")
    end
  end

  def self.agents_generated_src_path
    @agents_generated_src_path ||= begin
      path = File.expand_path("..", __FILE__)
      File.expand_path("#{path}/../agents_generated_source")
    end
  end

  def self.running_env_name
    @running_env_name
  end

  def self.id_code
    @id_code ||= SecureRandom.hex(2)
  end

  def self.what_is_internal_config
    @what_is_internal_config ||= begin
      [
        'dynamic_channel_str',
        'subscribe_presence',
        'subscribe_message',
        'subscribe_track'
      ]
    end
  end


  def self.get_dirs(path)
    Dir.entries(path).select {|entry| File.directory? File.join(path,entry) and !(entry =='.' || entry == '..') }
  end

  # create all agent classes an then subscribe to correct subscriber
  def self.init(running_env_name)
    @running_env_name = running_env_name
    RAGENT.api.mdi.tools.log.info("RAGENT init on '#{running_env_name}' env.")
    RAGENT.api.mdi.tools.log.info("RAGENT loading agents:")

    RAGENT.get_dirs(self.agents_project_src_path).each do |dir|
      if File.exist?("#{self.agents_project_src_path}/#{dir}/initial.rb")

        # create agent
        user_agent_class = UserAgentClass.new(dir)
        RAGENT.api.mdi.tools.log.info("Creating agent '#{user_agent_class.agent_name}' with:\n . protogen=#{user_agent_class.is_agent_has_protogen}\n . root_path=\"#{user_agent_class.root_path}\"\n . dyn_channels=#{user_agent_class.managed_message_channels}")
        RAGENT.user_class_subscriber.subscribe(user_agent_class)

        if user_agent_class.internal_config['subscribe_presence']
          RAGENT.user_class_presence_subscriber.subscribe(user_agent_class)
          RAGENT.api.mdi.tools.log.info("  Agent '#{user_agent_class.agent_name}' subscribe to presences")
        end
        if user_agent_class.internal_config['subscribe_message']
          RAGENT.user_class_message_subscriber.subscribe(user_agent_class)
          RAGENT.api.mdi.tools.log.info("  Agent '#{user_agent_class.agent_name}' subscribe to messages")
        end
        if user_agent_class.internal_config['subscribe_track']
          RAGENT.user_class_track_subscriber.subscribe(user_agent_class)
          RAGENT.api.mdi.tools.log.info("  Agent '#{user_agent_class.agent_name}' subscribe to tracks")
        end

      end
    end

    # verbose splash
    verboz_str = "\n\n"
    verboz_str += "+====================================================\n"
    verboz_str += "| RAGENT '#{RAGENT.id_code}' on env '#{RAGENT.running_env_name}' mounts #{RAGENT.user_class_subscriber.get_subscribers.size} agents :\n"
    RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
      verboz_str += "|  . #{user_agent_class.agent_name}\n"
    end
    verboz_str += "|\n"
    verboz_str += "| RAGENT manage message channels :\n"
    RAGENT.supported_message_channels.each do |channel|
      verboz_str += "|  . '#{channel}'\n"
    end
    verboz_str += "+====================================================\n"
    RAGENT.api.mdi.tools.log.info(verboz_str)

  end

  # return array of string
  def self.supported_message_channels
    # fetch in user_class_subscriber (do it once)
    @supported_message_channels ||= begin
      channels = []
      RAGENT.user_class_message_subscriber.get_subscribers.each do |user_agent_class|
        agent_channels = user_agent_class.managed_message_channels
        agent_channels.each do |channel|
          channels << channel
        end
      end
      channels
    end
  end

  # return an map of <channel_str>:<channel_id>
  def self.map_supported_message_channels
    channels = RAGENT.supported_message_channels

    f_map = Hash.new
    idx = 1000
    channels.each do |chan|
      f_map["#{chan}"] = idx
      idx+=1
    end
    f_map
  end

  # return an agent
  def self.get_agent_from_name(name)
    @get_agent_from_name_map ||= begin
      final_map = {}
      RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
        final_map["#{user_agent_class.agent_name}"] = user_agent_class
      end
      final_map
    end
    @get_agent_from_name_map[name]
  end

  # return hash of array
  def self.cron_tasks_to_map
    @cron_tasks_to_map ||= begin
      # init map
      final_map =  Hash.new
      RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
        final_map["#{user_agent_class.agent_name}"] = []
      end

      #RAGENT.api.mdi.tools.log.info(final_map)

      cron_content = File.read("#{RAGENT.agents_generated_src_path}/whenever_cron")

      # let's parse the cron_content to find cron commands for each running agent
      cron_content.each_line do |line|
        #puts "get_agents_cron_tasks line: #{line}"
        if line.include?('/bin/bash -l -c \'EXECUTE_WHENEVER')
          assigned_agent = ""
          RAGENT.user_class_subscriber.get_subscribers.each do |user_agent_class|
            agent_name = user_agent_class.agent_name
            p agent_name
            if line.include?(agent_name)
              assigned_agent = agent_name
            end
          end
          next unless assigned_agent != ""
          begin
            # extract cron schedule
            idx = line.index(" /bin/bash -l -c")
            cron_schedule = line[0..(idx-1)]
            # extract order
            ragent_order = line.split('{').second.split('}').first
            #RAGENT.api.mdi.tools.log.info "found #{ragent_order}"
            final_map["#{assigned_agent}"] << {
              'cron_schedule' => cron_schedule,
              'order' => "{#{ragent_order}}"
            }.to_json
          rescue Exception => e
            puts "get_agents_cron_tasks error on line #{line} :\n #{e}"
          end
        end
      end
      puts "get_agents_cron_tasks gives:\n#{final_map}"
      p 'get_agents_cron_tasks done'
      #RAGENT.api.mdi.tools.log.info(final_map)
      final_map
    end
  end

  def self.scheduled_tasks_start
    Rufus.run
  end

  def self.static_info
    @info ||= begin
      if File.readable? "#{RAGENT.agents_generated_src_path}/gen_additional_info.json"
        begin
          additional_info = JSON.parse(File.read("#{RAGENT.agents_generated_src_path}/gen_additional_info.json"))
        rescue => e
          additional_info = nil
        end
      end
      map = JSON.parse(File.read("#{RAGENT.agents_generated_src_path}/ragent_gen_info.json"))
      map['additional_info'] = additional_info
      map
    end
  end


end

RAGENT = RagentApi
