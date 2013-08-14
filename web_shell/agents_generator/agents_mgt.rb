#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

# rm -rf ~/workServ/SDK/ruby-agents-sdk/web_shell/agents_generator/exts/protogen/protocol_generator; cp -r protocol_generator ~/workServ/SDK/ruby-agents-sdk/web_shell/agents_generator/exts/protogen/


# gem
# see java generated
# agps portage with protogen
# who to communicate outside / need store ? db agent kind of fonctionnement
# message type stat
# gen doc protocol
# doc général review
# make a general agent example visible in the workspace

# temps/process/mémoire, chaque message est traité // -> oui

# sandjeeeb : what to give him
# how to release services in dev (flow)


require 'fileutils'
require 'securerandom'
require 'yaml'


module AgentsGenerator

  require_relative 'gemfile_mergator'

  def source_path()
      @ROOT_PATH_AGENT_MGT ||= File.expand_path("..", __FILE__)
  end

  def workspace_path()
    @ROOT_PATH_WORKSPACE ||= "#{source_path}/../../cloud_agents"
  end

  def generated_rb_path()
    @GENERATED_PATH = File.expand_path("#{source_path}/cloud_agents_generated")
  end

  def protogen_bin_path()
    @PROTOGEN_BIN_PATH ||= "#{source_path}/exts/protogen/protocol_generator/"
  end


  #########################################################################################################
  ## compile

  def add_to_rapport(txt)
    @AgentsGenerator_rapport_generation += "#{txt}\n"
    puts txt
  end

  def generate_agents_protogen() # we could do it into generate_agents but we separate generations to track errors easily
    @AgentsGenerator_rapport_generation = ""

    FileUtils.mkdir_p("#{generated_rb_path}")

    agents_to_run = get_run_agents

    # protogen
    agents_to_run.each { |agent|

      next unless File.exist?("#{workspace_path}/#{agent}/config/protogen.json")

      FileUtils.mkdir_p("#{workspace_path}/#{agent}/doc/protogen")

      # generate compil conf
      compil_opt = {
        "plugins" => ["mdi_sdk_vm_server_ruby"],
        "agent_name" => "#{agent}",
        "server_output_directory" => "#{generated_rb_path}/protogen_#{agent}"
      }
      add_to_rapport(">>> Generating Protogen for #{agent} agent with config :\n #{compil_opt}")
      File.open('/tmp/protogen_conf.json', 'w') { |file| file.write(compil_opt.to_json)}

      # create output dir for java jar
      #FileUtils.mkdir_p(compil_opt['device_output_directory'])
      # create dir for ruby side code
      FileUtils.mkdir_p(compil_opt['server_output_directory'])

      # call protogen
      command = "cd #{protogen_bin_path}; bundle install"
      output = `#{command}`
      add_to_rapport("")
      add_to_rapport("\n[[----------------------------------------------\nProtogen bundle install:\n #{output}\n----------------------------------------------]]\n")

      command = "cd #{protogen_bin_path}; bundle exec ruby protogen.rb #{workspace_path}/#{agent}/config/protogen.json /tmp/protogen_conf.json"
      add_to_rapport "running command #{command} :"
      output = `#{command}`

      add_to_rapport("")
      add_to_rapport("\n[[----------------------------------------------\nProtogen output:\n #{output}\n----------------------------------------------]]\n")
      add_to_rapport("Generating Protogen for #{agent} done \n")


      FileUtils.cp_r(Dir["#{source_path}/cloud_agents_generated/protogen_#{agent}/doc/*"],"#{workspace_path}/#{agent}/doc/protogen/")

      add_to_rapport("Protogen doc deployed \n")
    }

    @AgentsGenerator_rapport_generation
  end

  def generate_agents()
    @AgentsGenerator_rapport_generation = ""

    FileUtils.mkdir_p("#{generated_rb_path}")

    add_to_rapport("\n========= generate_agents start ===============")

    # get agents to run
    agents_to_run = get_run_agents

    add_to_rapport("generate_agents of #{agents_to_run.join(', ')}")

    agents_generated_code = ""


    template_agent_src = File.read("#{source_path}/template_agent.rb_")

    # template generation
    agents_to_run.each { |agent|
      clean_class_name = "#{agent}"
      clean_class_name.gsub!('-','_')

      template_agent = template_agent_src.clone
      template_agent.gsub!('XX_PROJECT_NAME',"#{agent}")
      template_agent.gsub!('XX_CLEAN_PROJECT_NAME',clean_class_name)
      template_agent.gsub!('XX_PROJECT_ROOT_PATH',"#{workspace_path}/#{agent}")
      agents_generated_code += template_agent

      agents_generated_code += "\$#{clean_class_name}_initial = Agent_#{clean_class_name}.new\n\n\n"
    }
    agents_generated_code += "\n\n\n\n"


    # check if no subscription is setted
    agents_to_run.each { |agent|
      sub_p = get_agent_is_sub_presence(agent)
      sub_m = get_agent_is_sub_message(agent)
      sub_t = get_agent_is_sub_track(agent)
      if sub_p != true && sub_m != true && sub_t != true
        PUNK.start('subcription_none')
        PUNK.end('subcription_p','ko','',"AGENT:#{agent}TNEGA didn't subscribe to anything")
      end
    }

    # forward messages to agent
    agents_generated_code += "\n"
    agents_generated_code += "def handle_presence(presence)\n"
    agents_to_run.each { |agent|

      sub_p = get_agent_is_sub_presence(agent)
      if sub_p != true && sub_p != false
        PUNK.start('subcription_p')
        sub_p = false
        CC.logger.info("Presence subcription configuration not found ! (sub_p=#{sub_p})")
        CC.logger.info("Please add a \n\"subscribe_presence: false\"\n or\n \"subscribe_presence: true\"\n line in your agent config file.")
        CC.logger.info("This parameter will allow or forbidden your agent to receive presence notification.")
        PUNK.end('subcription_p','ko','',"AGENT:#{agent}TNEGA missing configuration")
      end

      if sub_p
        agents_generated_code += "  begin\n"
        agents_generated_code += "    \$#{agent}_initial.handle_presence(presence)\n"
        agents_generated_code += "    PUNK.end('handle','ok','process',\"AGENT:#{agent}TNEGA callback PRESENCE '\#{presence.type}'\")\n"
        agents_generated_code += "  rescue => e\n"
        agents_generated_code += "    CC.logger.error('Server: /presence error on agent #{agent} while handle_presence')\n"
        agents_generated_code += "    CCS.print_ruby_exeption(e)\n"
        agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['err_while_process'][0] += 1\n"
        agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['total_error'] += 1\n"
        agents_generated_code += "    PUNK.end('handle','ko','process','AGENT:#{agent}TNEGA callback PRESENCE fail')\n"
        agents_generated_code += "  end\n"
      end
    }
    agents_generated_code += "end\n\n"

    agents_generated_code += "def handle_message(message)\n"
    agents_to_run.each { |agent|

      sub_m = get_agent_is_sub_message(agent)
      if sub_m != true && sub_m != false
        PUNK.start('subcription_m')
        sub_m = false
        CC.logger.info("Message subcription configuration not found ! (sub_m=#{sub_m})")
        CC.logger.info("Please add a \n\"subscribe_message: false\"\n or\n \"subscribe_message: true\"\n line in your agent config file.")
        CC.logger.info("This parameter will allow or forbidden your agent to receive message notification.")
        PUNK.end('subcription_m','ko','',"AGENT:#{agent}TNEGA missing configuration")
      end

      if sub_m
        agents_generated_code += "  begin\n"
        agents_generated_code += "    \$#{agent}_initial.handle_message(message)\n"
        agents_generated_code += "    PUNK.end('handle','ok','process',\"AGENT:#{agent}TNEGA callback MSG[\#{crop_ref(message.id,4)}]\")\n"
        agents_generated_code += "  rescue => e\n"
        agents_generated_code += "    CC.logger.error('Server: /message error on agent #{agent} while handle_message')\n"
        agents_generated_code += "    CCS.print_ruby_exeption(e)\n"
        agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['err_while_process'][1] += 1\n"
        agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['total_error'] += 1\n"
        agents_generated_code += "    PUNK.end('handle','ko','process',\"AGENT:#{agent}TNEGA callback MSG[\#{crop_ref(message.id,4)}] fail\")\n"
        agents_generated_code += "  end\n"
      end
    }
    agents_generated_code += "end\n\n"

    agents_generated_code += "def handle_track(track)\n"
    agents_to_run.each { |agent|

      sub_t = get_agent_is_sub_track(agent)
      if  sub_t != true && sub_t != false
        PUNK.start('subcription_t')
        sub_t = false
        CC.logger.info("Track subcription configuration not found ! (sub_t=#{sub_t})")
        CC.logger.info("Please add a \n\"subscribe_track: false\"\n or\n \"subscribe_track: true\"\n line in your agent config file.")
        CC.logger.info("This parameter will allow or forbidden your agent to receive track notification.")
        PUNK.end('subcription_t','ko','',"AGENT:#{agent}TNEGA missing configuration")
      end

      if sub_t
        agents_generated_code += "  begin\n"
        agents_generated_code += "    \$#{agent}_initial.handle_track(track)\n"
        agents_generated_code += "    PUNK.end('handle','ok','process',\"AGENT:#{agent}TNEGA callback TRACK\")\n"
        agents_generated_code += "  rescue => e\n"
        agents_generated_code += "    CC.logger.error('Server: /track error on agent #{agent} while handle_track')\n"
        agents_generated_code += "    CCS.print_ruby_exeption(e)\n"
        agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['err_while_process'][2] += 1\n"
        agents_generated_code += "    SDK_STATS.stats['agents']['#{agent}']['total_error'] += 1\n"
        agents_generated_code += "    PUNK.end('handle','ko','process',\"AGENT:#{agent}TNEGA callback TRACK fail\")\n"
        agents_generated_code += "  end\n"
      end
    }
    agents_generated_code += "end\n\n"

    agents_generated_code += "def handle_order(order)\n"
    agents_to_run.each { |agent|
      agents_generated_code += "  if order.agent == '#{agent}'\n"
      agents_generated_code += "    begin\n"
      agents_generated_code += "      \$#{agent}_initial.handle_order(order)\n"
      agents_generated_code += "      PUNK.end('handle','ok','process',\"AGENT:#{agent}TNEGA callback ORDER '\#{order.code}' \")\n"
      agents_generated_code += "    rescue => e\n"
      agents_generated_code += "      CC.logger.error(\"Server: /remote_call error on agent #{agent} while executing order \#{order.code}\")\n"
      agents_generated_code += "      CCS.print_ruby_exeption(e)\n"
      agents_generated_code += "      SDK_STATS.stats['agents']['#{agent}']['err_while_process'][3] += 1\n"
      agents_generated_code += "      SDK_STATS.stats['agents']['#{agent}']['total_error'] += 1\n"
      agents_generated_code += "      PUNK.end('handle','ko','process',\"AGENT:#{agent}TNEGA callback ORDER '\#{order.code}' fail\")\n"
      agents_generated_code += "    end\n"
      agents_generated_code += "  end\n"
    }
    agents_generated_code += "end\n\n"


    File.open("#{generated_rb_path}/generated.rb", 'w') { |file| file.write(agents_generated_code) }

    add_to_rapport("Templates generated done\n")

    generate_Gemfile


    # check agent name here, restore if note here
    agents_to_run.each { |agent|
      if !(File.exist?("#{workspace_path}/#{agent}/.agent_name"))
        File.open("#{workspace_path}/#{agent}/.agent_name", 'w') { |file| file.write(agent) }
      end
    }

    # check config exist
    agents_to_run.each { |agent|
      if !(File.exist?("#{workspace_path}/#{agent}/config/#{agent}.yml.example"))
        restore_default_config(agent)
      end
    }

    add_to_rapport("Config checked\n")

    #  generad dyn channel list
    dyn_channels = Hash.new()
    channel_int = 1000
    agents_to_run.each { |agent|
      channels = get_agent_dyn_channel(agent)
      channels.each { |chan|
        dyn_channels[chan] = channel_int
        channel_int +=1
      }
    }

    File.open("#{source_path}/cloud_agents_generated/dyn_channels.yml", 'w+') { |file| file.write(dyn_channels.to_yaml) }

    add_to_rapport("Dynamic channel merged\n")

    add_to_rapport('generate_agents done')

    @AgentsGenerator_rapport_generation
  end

  def generate_Gemfile()

    # get agents to run
    agents_to_run = get_run_agents


    # Merge Gemfile
    agents_Gemfiles = []
    agents_to_run.each { |agent|
      agents_Gemfiles << get_agent_Gemfile_content(agent)
    }
    master_GemFile = File.read("#{source_path}/../local_cloud/Gemfile.master")

    gemFile_content = merge_gem_file(master_GemFile, agents_Gemfiles)
    puts "GemFile_content =\n #{gemFile_content}\n\n"

    File.open("#{source_path}/../local_cloud/Gemfile", 'w') { |file| file.write(gemFile_content) }

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
    name.gsub!(' ', '_')
    name.gsub!('-', '_')

    #verify if folder/file already exist
    return false if File.exists?("#{workspace_path}/#{name}")

    project_path = "#{workspace_path}/#{name}"
    p "Creating project #{name} ..."

    #create directory
    Dir::mkdir(project_path)

    # create file guid
    File.open("#{project_path}/.mdi_cloud_agent_guid", 'w') { |file| file.write(generate_new_guid()) }

    # init agent name
    File.open("#{project_path}/.agent_name", 'w') { |file| file.write(name) }


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
    FileUtils.touch("#{source_path}/.agents_to_run")
    agents = File.read("#{source_path}/.agents_to_run").split(';')

    #for each verify that agent is still here and valid
    remove_unvalid_agents(agents)
  end

  # return an array of string
  def get_agent_dyn_channel(name)
    return [] unless File.directory?("#{workspace_path}/#{name}")
    cnf = {}
    if File.exist?("#{workspace_path}/#{name}/config/#{name}.yml")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml"))['development']
    elsif File.exist?("#{workspace_path}/#{name}/config/#{name}.yml.example")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml.example"))['development']
    end

    channels = cnf['Dynamic_channel_str']
    channels = cnf['dynamic_channel_str'] if channels == nil

    if channels.is_a? String
      [] << channels
    elsif channels.is_a? Hash
      channels
    else
      p "get_agent_dyn_channel: unkown format of #{channels} for dynchannels of agent #{name}"
    end
  end


  def get_agent_is_sub_presence(name)
    return nil unless File.directory?("#{workspace_path}/#{name}")
    cnf = {}
    if File.exist?("#{workspace_path}/#{name}/config/#{name}.yml")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml"))['development']
    elsif File.exist?("#{workspace_path}/#{name}/config/#{name}.yml.example")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml.example"))['development']
    end

    cnf['subscribe_presence']
  end

  def get_agent_is_sub_message(name)
    return nil unless File.directory?("#{workspace_path}/#{name}")
    cnf = {}
    if File.exist?("#{workspace_path}/#{name}/config/#{name}.yml")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml"))['development']
    elsif File.exist?("#{workspace_path}/#{name}/config/#{name}.yml.example")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml.example"))['development']
    end

    cnf['subscribe_message']
  end

  def get_agent_is_sub_track(name)
    return nil unless File.directory?("#{workspace_path}/#{name}")
    cnf = {}
    if File.exist?("#{workspace_path}/#{name}/config/#{name}.yml")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml"))['development']
    elsif File.exist?("#{workspace_path}/#{name}/config/#{name}.yml.example")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml.example"))['development']
    end

    cnf['subscribe_track']
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

  #return true if valid todo: add more case that return false (gem file dynchannel etc), + print when rejected
  def is_agent_valid(name)
    return false unless File.directory?("#{workspace_path}/#{name}")
    return false unless File.exists?("#{workspace_path}/#{name}/.mdi_cloud_agent_guid")
    return false unless File.exists?("#{workspace_path}/#{name}/initial.rb")
    return true
  end

  def get_agent_Gemfile_content(name)
    return "" unless File.exists?("#{workspace_path}/#{name}/Gemfile")
    File.read("#{workspace_path}/#{name}/Gemfile")
  end

  def get_agent_whenever_content(name)
    return "" unless File.exists?("#{workspace_path}/#{name}/config/schedule.rb")
    content = ''
    #content += "cron_tasks_folder=\'#{workspace_path}/#{name}/cron_tasks\'\n"
    content += "job_type :execute_order, \'curl -i -H \"Accept: application/json\" -H \"Content-type: application/json\" -X POST -d \\\'{\"agent\":\"#{name}\", \"order\":\":task\", \"params\":\":params\"}\\\' http://localhost:5001/remote_call\'\n"
    #content += "job_type :rake, echo :task\n"
    #content += "job_type :runner, echo :task\n"
    #content += "job_type :command, echo :task\n"

    content += File.read("#{workspace_path}/#{name}/config/schedule.rb")
  end

  def get_agents_cron_tasks(running_agents)
    @agents_cron_tasks ||= begin
      # init map
      final_map = {}
      running_agents.each { |agent|
        final_map[agent] = []
      }
      # run whenever
      `bundle exec whenever > /tmp/whenever_cron`
      cron_content = File.read('/tmp/whenever_cron')

      # let's parse the cron_content to find cron commands for each running agent
      cron_content.each_line { |line|
        #puts "get_agents_cron_tasks line: #{line}"
        if line.include?('/bin/bash -l -c \'curl')
          assigned_agent = ""
          running_agents.each { |agent|
            if line.include?(agent)
              assigned_agent = agent
            end
          }
          next unless assigned_agent != ""
          begin
            #extract {}
            in_par_cmd = line.split('{').second.split('}').first
            #puts "found #{in_par_cmd}"
            final_map[assigned_agent] << "{#{in_par_cmd}}"
          rescue Exception => e
            puts "get_agents_cron_tasks error on line #{line} :\n #{e}"
          end
        end
      }
      puts "get_agents_cron_tasks gives:\n#{final_map}"
      p 'get_agents_cron_tasks done'
    rescue => e
      p 'get_agents_cron_tasks fail'
      print_ruby_exeption(e)
    end

    final_map
  end

  def set_run_agents(agents)
    FileUtils.touch("#{source_path}/.agents_to_run")
    File.open("#{source_path}/.agents_to_run", 'w') { |file| file.write(agents.join(';')) }
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

