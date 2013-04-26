require 'fileutils'
require 'securerandom'
require 'yaml'


#########################################################################################################
## compile

def generate_agents()
  # get agents to run
  agents_to_run = get_run_agents

  agents_generated_code = ""
  agents_Gemfile = ""

  agents_generated_code_handle_presence = ""
  agents_generated_code_handle_message = ""
  agents_generated_code_handle_track = ""

  agents_to_run.each { |agent|
    agents_generated_code += "\nrequire_relative \"../../cloud_agents/#{agent}/Initial\"\n"
    agents_generated_code += "\$#{agent}_initial = Agent_#{agent}.new\n"

    agents_generated_code_handle_presence += "  $main_server_logger.debug(\"handle_presence: pushing presence to #{agent} ..................\")\n"
    agents_generated_code_handle_presence += "  \$#{agent}_initial.handle_presence(meta, payload, account)\n"
    agents_generated_code_handle_message += "  $main_server_logger.debug(\"handle_message: pushing message to #{agent} ..................\")\n"
    agents_generated_code_handle_message += "  \$#{agent}_initial.handle_message(meta, payload, account)\n"
    agents_generated_code_handle_track += "  $main_server_logger.debug(\"handle_track: pushing track to #{agent} ..................\")\n"
    agents_generated_code_handle_track += "  \$#{agent}_initial.handle_track(meta, payload, account)\n"

    agents_Gemfile += get_agent_Gemfile_content(agent) + "\n"
  }

  agents_generated_code += "\n"
  agents_generated_code += "def handle_presence(meta, payload, account)\n"
  agents_generated_code += agents_generated_code_handle_presence
  agents_generated_code += "end\n"
  agents_generated_code += "\n"
  agents_generated_code += "def handle_message(meta, payload, account)\n"
  agents_generated_code += agents_generated_code_handle_message
  agents_generated_code += "end\n"
  agents_generated_code += "\n"
  agents_generated_code += "def handle_track(meta, payload, account)\n"
  agents_generated_code += agents_generated_code_handle_track
  agents_generated_code += "end\n"

  File.open('../cloud_agents_generated/generated.rb', 'w') { |file| file.write(agents_generated_code) }
  File.open('../cloud_agents_generated/GemFile', 'w') { |file| file.write(agents_Gemfile) }

  #  generad dyn channel list
  dyn_channels_str = get_agents_dyn_channel(get_available_agents())
  dyn_channels = Hash.new()
  channel_int = 1000
  dyn_channels_str.each_pair do |name,channel_str|
    dyn_channels[channel_str] = channel_int
    channel_int +=1
  end

  File.open('../cloud_agents_generated/dyn_channels.yml', 'w+') { |file| file.write(dyn_channels.to_yaml) }
end

def generated_get_dyn_channel()
  YAML::load(File.open('../cloud_agents_generated/dyn_channels.yml'))
end




#########################################################################################################
## agent mgt

#return true if success
def create_new_agent(name)

  #todo filter name character, only letter and '_'

  #verify if folder/file already exist
  return false if File.exists?("../../cloud_agents/#{name}")

  project_path = "../../cloud_agents/#{name}"
  p "Creating project #{name} ..."

  #create directory
  Dir::mkdir(project_path)

  # create file guid
  File.open("#{project_path}/.mdi_cloud_agent_guid", 'w') { |file| file.write(generate_new_guid()) }

  #copy sample project
  FileUtils.cp_r(Dir['../sample_agent/*'],"#{project_path}")

  # Match and replace name project stuff in content
  match_and_replace_in_folder(project_path,"XXProjectName",name)


  return true
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
  dirs = get_dirs('../../cloud_agents/')
  remove_unvalid_agents(dirs)
end

#return [name]
def get_run_agents()
  #read .agents_to_run file (if not exist create one)
  FileUtils.touch('.agents_to_run')
  agents = File.read('.agents_to_run').split(';')
  #for each verify that agent is still here and valid
  remove_unvalid_agents(agents)
end

def get_agent_dyn_channel(name)
  return "" unless File.directory?("../../cloud_agents/#{name}")
  cnf = YAML::load(File.open("../../cloud_agents/#{name}/config/dynamic_channel.yml"))
  cnf['Channel_str']
end

def set_agent_dyn_channel(name, dyn_channel)
  cnf = Hash.new()
  cnf['Channel_str'] = dyn_channel
  File.open("../../cloud_agents/#{name}/config/dynamic_channel.yml", 'w+') {|f| f.write(cnf.to_yaml) }
end


def get_agents_dyn_channel(array)
  dyn_channel = Hash.new()
  array.each { |agent_name|
    dyn_channel[agent_name] = get_agent_dyn_channel(agent_name)
  }
  dyn_channel
end

#########################################################################################################
## Basic tools

def generate_new_guid()
  SecureRandom.base64
end

def get_dirs(path)
  Dir.entries(path).select {|entry| File.directory? File.join(path,entry) and !(entry =='.' || entry == '..') }
end

def get_files(path)
  Dir.entries(path).select {|f| File.file? File.join(path,f)}
end

def is_agent_exist(name)
  File.directory?("../../cloud_agents/#{name}")
end

#return true if valid todo: add more case that return false (gem file dynchannel etc), + print when rejected
def is_agent_valid(name)
  return false unless File.directory?("../../cloud_agents/#{name}")
  File.exists?("../../cloud_agents/#{name}/.mdi_cloud_agent_guid")
end


def get_agent_Gemfile_content(name)
  return false unless File.directory?("../../cloud_agents/#{name}")
  File.read("../../cloud_agents/#{name}/Gemfile")
end

def set_run_agents(agents)
  FileUtils.touch('.agents_to_run')
  File.open('.agents_to_run', 'w') { |file| file.write(agents.join(';')) }
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
  return "" unless File.directory?("../../cloud_agents/#{name}")
  return "" unless File.exists?("../../cloud_agents/#{name}/.mdi_cloud_agent_guid")
  File.read("../../cloud_agents/#{name}/.mdi_cloud_agent_guid")
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