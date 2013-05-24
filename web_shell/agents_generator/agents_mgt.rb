#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'fileutils'
require 'securerandom'
require 'yaml'


module AgentsGenerator

  def source_path()
      @ROOT_PATH_AGENT_MGT ||= File.expand_path("..", __FILE__)
  end

  def workspace_path()
    @ROOT_PATH_WORKSPACE ||= "#{source_path}/../../cloud_agents"
  end


  #########################################################################################################
  ## compile

  def generate_agents()
    # get agents to run
    agents_to_run = get_run_agents


    puts "generate_agents of #{agents_to_run.join(', ')}"
    p 'generate_agents'

    agents_generated_code = ""

    template_agent_src = File.read("#{source_path}/template_agent.rb_")

    # template generation
    agents_to_run.each { |agent|
      template_agent = template_agent_src.clone
      template_agent.gsub!('XX_PROJECT_NAME',"#{agent}")
      template_agent.gsub!('XX_PROJECT_ROOT_PATH',"#{workspace_path}/#{agent}")
      agents_generated_code += template_agent

      agents_generated_code += "\$#{agent}_initial = Agent_#{agent}.new\n\n\n"
    }
    agents_generated_code += "\n\n\n\n"

    # forward messages to agent
    agents_generated_code += "\n"
    agents_generated_code += "def handle_presence(meta, payload, account)\n"
    agents_to_run.each { |agent|
      agents_generated_code += "  begin\n"
      #agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['received'][0] += 1\n"
      agents_generated_code += "    \$#{agent}_initial.handle_presence(meta, payload, account)\n"
      agents_generated_code += "  rescue => e\n"
      agents_generated_code += "    CC_SDK.logger.error('Server: /presence error while handle_presence on agent #{agent}')\n"
      agents_generated_code += "    print_ruby_exeption(e)\n"
      agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['err_while_process'][0] += 1\n"
      agents_generated_code += "  end\n"
    }
    agents_generated_code += "end\n\n"


    agents_generated_code += "def handle_message(meta, payload, account)\n"
    agents_to_run.each { |agent|
      agents_generated_code += "  begin\n"
      #agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['received'][1] += 1\n"
      agents_generated_code += "    \$#{agent}_initial.handle_message(meta, payload, account)\n"
      agents_generated_code += "  rescue => e\n"
      agents_generated_code += "    CC_SDK.logger.error('Server: /message error while handle_message on agent #{agent}')\n"
      agents_generated_code += "    print_ruby_exeption(e)\n"
      agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['err_while_process'][1] += 1\n"
      agents_generated_code += "  end\n"
    }
    agents_generated_code += "end\n\n"

    agents_generated_code += "def handle_track(meta, payload, account)\n"
    agents_to_run.each { |agent|
      agents_generated_code += "  begin\n"
      #agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['received'][2] += 1\n"
      agents_generated_code += "  \$#{agent}_initial.handle_track(meta, payload, account)\n"
      agents_generated_code += "  rescue => e\n"
      agents_generated_code += "    CC_SDK.logger.error('Server: /track error while handle_track on agent #{agent}')\n"
      agents_generated_code += "    print_ruby_exeption(e)\n"
      agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['err_while_process'][2] += 1\n"
      agents_generated_code += "  end\n"
    }
    agents_generated_code += "end\n"

    File.open("#{source_path}/cloud_agents_generated/generated.rb", 'w') { |file| file.write(agents_generated_code) }

    # Gemfile
    agents_Gemfile = ""

    agents_to_run.each { |agent|
      agents_Gemfile += get_agent_Gemfile_content(agent) + "\n"
    }
    File.open("#{source_path}/cloud_agents_generated/Gemfile", 'w') { |file| file.write(agents_Gemfile) }

    # check config exist
    agents_to_run.each { |agent|
      if !(File.exist?("#{workspace_path}/#{agent}/config/#{agent}.yml.example"))
        restore_default_config(agent)
      end
    }

    #  generad dyn channel list
    dyn_channels_str = get_agents_dyn_channel(get_available_agents())
    dyn_channels = Hash.new()
    channel_int = 1000
    dyn_channels_str.each_pair do |name,channel_str|
      dyn_channels[channel_str] = channel_int
      channel_int +=1
    end

    File.open("#{source_path}/cloud_agents_generated/dyn_channels.yml", 'w+') { |file| file.write(dyn_channels.to_yaml) }
  end

  def generated_get_dyn_channel()
    YAML::load(File.open("#{source_path}/cloud_agents_generated/dyn_channels.yml"))
  end


  def generated_get_agents_whenever_content()
    agents_to_run = get_run_agents
    agents_whenever=''

    agents_to_run.each { |agent|
      agents_whenever += get_agent_whenever_content(agent) + "\n"
    }
    agents_whenever
  end

  #########################################################################################################
  ## agent mgt

  #return true if success
  def create_new_agent(name)

    #todo filter name character, only letter and '_'

    #verify if folder/file already exist
    return false if File.exists?("#{workspace_path}/#{name}")

    project_path = "#{workspace_path}/#{name}"
    p "Creating project #{name} ..."

    #create directory
    Dir::mkdir(project_path)

    # create file guid
    File.open("#{project_path}/.mdi_cloud_agent_guid", 'w') { |file| file.write(generate_new_guid()) }


    #copy sample project
    FileUtils.cp_r(Dir["#{source_path}/sample_agent/*"],"#{project_path}")

    #rename config file
    FileUtils.mv("#{project_path}/config/config.yml.example", "#{project_path}/config/#{name}.yml.example")

    # Match and replace name project stuff in content
    match_and_replace_in_folder(project_path,"XXProjectName",name)

    return true
  end

  def restore_default_config(name)
    puts "restore_default_config for agent #{name}"
    project_path = "#{workspace_path}/#{name}"
    FileUtils.cp("#{source_path}/sample_agent/config/config.yml.example", "#{project_path}/config/#{name}.yml.example")
    match_and_replace_in_folder("#{project_path}/config","XXProjectName", name)
  end


  def add_agent_to_run_list(name)
   return false unless is_agent_valid(name)
   run_list = get_run_agents
   run_list.delete(name)
   run_list.push(name)
   set_run_agents(run_list)
  end

  def remove_agent_from_run_list(name)
   run_list = get_run_agents
   run_list.delete(name)
   set_run_agents(run_list)
  end

  #return [name]
  def get_available_agents()
    dirs = get_dirs("#{workspace_path}")
    remove_unvalid_agents(dirs)
  end

  #return [name]
  def get_run_agents()
    #read .agents_to_run file (if not exist create one)
    FileUtils.touch("#{source_path}/.agent_to_run")
    agents = File.read("#{source_path}/.agent_to_run").split(';')

    #for each verify that agent is still here and valid
    remove_unvalid_agents(agents)
  end

  def get_agent_dyn_channel(name)
    return "" unless File.directory?("#{workspace_path}/#{name}")
    cnf = nil
    if File.exist?("#{workspace_path}/#{name}/config/#{name}.yml")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml"))['development']
    elsif File.exist?("#{workspace_path}/#{name}/config/#{name}.yml.example")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml.example"))['development']
    end
    cnf['Dynamic_channel_str']
  end


  def get_agents_dyn_channel(array)
    dyn_channel = Hash.new()
    array.each { |agent_name|
      dyn_channel[agent_name] = get_agent_dyn_channel(agent_name)
      puts "get_agents_dyn_channel USING #{dyn_channel[agent_name]}"
    }
    dyn_channel
  end

  #########################################################################################################
  ## Basic tools

  def get_sdk_version()
    @sdk_version ||= File.read('../../version.txt')
  end

  def generate_new_guid()
    get_sdk_version + ";" + SecureRandom.base64
  end

  def get_dirs(path)
    Dir.entries(path).select {|entry| File.directory? File.join(path,entry) and !(entry =='.' || entry == '..') }
  end

  def get_files(path)
    Dir.entries(path).select {|f| File.file? File.join(path,f)}
  end

  def is_agent_exist(name)
    File.directory?("#{workspace_path}/#{name}")
  end

  #return true if valid todo: add more case that return false (gem file dynchannel etc), + print when rejected
  def is_agent_valid(name)
    return false unless File.directory?("#{workspace_path}/#{name}")
    File.exists?("#{workspace_path}/#{name}/.mdi_cloud_agent_guid")
    File.exists?("#{workspace_path}/#{name}/initial.rb")
  end


  def get_agent_Gemfile_content(name)
    return "" unless File.exists?("#{workspace_path}/#{name}/Gemfile")
    File.read("#{workspace_path}/#{name}/Gemfile")
  end

  def get_agent_whenever_content(name)
    return "" unless File.exists?("#{workspace_path}/#{name}/config/schedule.rb")

    content = "cron_tasks_folder=\'#{workspace_path}/#{name}/cron_tasks\'\n"
    content += File.read("#{workspace_path}/#{name}/config/schedule.rb")
  end

  def set_run_agents(agents)
    FileUtils.touch("#{source_path}/.agent_to_run")
    File.open("#{source_path}/.agent_to_run", 'w') { |file| file.write(agents.join(';')) }
  end

  def remove_unvalid_agents(array)
    out = []
    array.each { |a|
      if is_agent_valid(a)
        out << a
      end
    }
    out
  end

  def get_guid_from_name(name)
    return "" unless File.exists?("#{workspace_path}/#{name}/.mdi_cloud_agent_guid")
    File.read("#{workspace_path}/#{name}/.mdi_cloud_agent_guid")
  end

  def match_and_replace_in_folder(path, pattern, replace)
    get_files(path).each do |file_name|
      file_full = "#{path}/#{file_name}"
      puts "match_and_replace in file #{file_full}"
      text = File.read(file_full)
      File.open(file_full, 'w') { |file| file.write(text.gsub(pattern, replace)) }
    end
    get_dirs(path).each{ |dir|
      match_and_replace_in_folder("#{path}/#{dir}", pattern, replace)
    }
  end

  #########################################################################################################

end

GEN = AgentsGenerator