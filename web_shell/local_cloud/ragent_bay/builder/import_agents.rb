#!/usr/bin/env ruby

#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


# input : path of master gem file
#         path of output of gem file
#         paths of agents root paths to import


# what it does :
# flush generated and src folder
# copy agent
# generate cron file
# generate gemfile
# generate protogen


# ex :
# bundle exec ruby import_agents.rb ../../Gemfile.master ../../Gemfile /home/demomp_x/workServ/SDK/agents_workspace/data_injection_agent /home/demomp_x/workServ/SDK/agents_workspace/protogen_fun_agent

# bundle exec ruby import_agents.rb ../../Gemfile.master ../../Gemfile /home/demomp_x/workServ/SDK/agents_workspace/data_injection_agent /home/demomp_x/workServ/SDK/agents_workspace/protogen_fun_agent /home/demomp_x/workServ/SDK/agents_workspace/sequences_test

# bundle exec ruby import_agents.rb ../../Gemfile.master ../../Gemfile /home/demomp_x/workServ/SDK/agents_workspace/data_injection_agent

# cd /home/demomp_x/workServ/SDK/ruby-agents-sdk/web_shell/local_cloud/ragent_bay/builder
# bundle exec ruby import_agents.rb ../../Gemfile.master ../../Gemfile /home/demomp_x/workServ/SDK/agents_workspace/data_injection_agent /home/demomp_x/workServ/SDK/agents_workspace/ragent_basic_tests_agent


require 'bundler'
require 'json'
require 'securerandom'


def here_path
  File.expand_path("..", __FILE__)
end


def agents_src_path
  "#{here_path}/../agents_project_source"
end

def agents_generated_path
  "#{here_path}/../agents_generated_source"
end


def reset_folder(folder_path)
  if File.directory?(folder_path)
    FileUtils.rm_r(folder_path, :secure => true)
  end
  FileUtils.mkdir_p(folder_path)
end

def delete_file_if_exist(path)
  if File.exist? path
    File.delete(path)
  end
end


def get_agent_whenever_content(name)
  return '' unless File.exists?("#{agents_src_path}/#{name}/config/schedule.rb")
  content = "job_type :execute_order, \'EXECUTE_WHENEVER {\"agent\":\"#{name}\", \"order\":\":task\", \"params\":\":params\"}\'\n"
  content += File.read("#{agents_src_path}/#{name}/config/schedule.rb")
end

def get_agent_Gemfile_content(name)
  return '' unless File.exists?("#{agents_src_path}/#{name}/Gemfile")
  File.read("#{agents_src_path}/#{name}/Gemfile")
end

def protogen_bin_path
  @PROTOGEN_BIN_PATH ||= "#{here_path}/../exts/protogen/protocol_generator/"
end


# in any case, we flush last gen done
# delete_file_if_exist("#{agents_generated_path}/gen_agents_imported")
# delete_file_if_exist("#{agents_generated_path}/gen_errors")
# delete_file_if_exist("#{agents_generated_path}/gen_success")
# gen_errors = []

### manage input ###
if ARGV.size < 2
  gen_errors
  raise "not enough argument"
end

p ARGV

master_gem_path = ARGV[0]
p "master_gem_path=#{master_gem_path}"
master_gem_file_content = File.read(master_gem_path)
gem_path = ARGV[1]
p "gem_path=#{gem_path}"
additionnal_info_file_path = ARGV[2]
p "additionnal_info_file_path=#{additionnal_info_file_path}"
agents_root_path = ARGV[3..-1]

additionnal_info = ""
p "Looking for '#{additionnal_info_file_path}' ..."
if File.readable?(additionnal_info_file_path)
  additionnal_info = File.read(additionnal_info_file_path)
  p "Found additionnal_info: #{additionnal_info}"
end


agents_root_path.each do |a_path|
  if !(File.directory?(a_path))
    raise "path #{a} not found"
  end
end


p "Import #{agents_root_path}"


### delete old project ###
reset_folder(agents_src_path)
reset_folder(agents_generated_path)


### copy new ###
agents_root_path.each do |path|
  FileUtils.cp_r(path, agents_src_path)
  p "copied '#{path}'"
end


### generate whenever to cron ###
whenever_content = ''
agents_root_path.each do |a_path|
  agent_name = File.basename(a_path)
  whenever_content += get_agent_whenever_content(agent_name) + "\n"
end
FileUtils.mkdir_p("#{here_path}/config")
File.open("#{here_path}/config/schedule.rb", 'w') { |file| file.write(whenever_content) }

# call whenever
Bundler.with_clean_env do
  `cd #{here_path};bundle exec whenever > #{agents_generated_path}/whenever_cron`
end

puts "cron tasks:\n #{File.read("#{agents_generated_path}/whenever_cron")}"

# write generation info add:agent list with version, ragent version
ragent_gen_info = {
  'ragent_id' => SecureRandom.hex(2)
  }.to_json
File.open("#{agents_generated_path}/ragent_gen_info.json", 'w') { |file| file.write(ragent_gen_info) }

# generate gemfile from copied
require_relative 'gemfile_mergator'

agents_Gemfiles = []
agents_root_path.each do |a_path|
  agent_name = File.basename(a_path)
  p get_agent_Gemfile_content(agent_name)
  agents_Gemfiles << get_agent_Gemfile_content(agent_name)
end

gemFile_content = merge_gem_file(master_gem_file_content, agents_Gemfiles)
p "Saving to '#{gem_path}'"

File.open(gem_path, 'w') { |file| file.write(gemFile_content) }
puts "Gemfile:\n #{File.read(gem_path)}\n\n"



# generate protogen from copied
protogen_apis_to_include = []
Bundler.with_clean_env do

  # bundle install protogen
  command = "cd #{protogen_bin_path}; bundle install"
  output = `#{command}`
  puts "protogen bundle install:\n #{output}\n\n"

  agents_root_path.each do |a_path|
    agent_name = File.basename(a_path)

    #PUNK.start('a')

    protocol_files = Dir.glob("#{agents_src_path}/#{agent_name}/config/*.protogen").reject{|file| File.directory?(file)}.map{|file| "#{agents_src_path}/#{agent_name}/config/#{File.basename(file)}"}
    if protocol_files.size == 0
      p "Agent '#{agent_name}': no protogen files found in 'config' directory. Skip."
      #PUNK.end('a','ok','',"SERVER no Protogen for agent #{agent}")
      next
     end

    # generate compil conf
    compil_opt = {
      "plugins" => ["mdi_sdk_vm_server_ruby"],
      "agent_name" => "#{agent_name}",
      "server_output_directory" => "#{agents_generated_path}/protogen_#{agent_name}",
      "user_callbacks" => "#{agents_src_path}/#{agent_name}/protogen"
    }
    File.open('/tmp/protogen_conf.json', 'w') { |file| file.write(compil_opt.to_json)}

    # create dir for ruby side code
    FileUtils.mkdir_p(compil_opt['server_output_directory'])


    # run protogen generation
    command = "cd #{protogen_bin_path}; bundle exec ruby protogen.rb #{protocol_files.join(" ")} /tmp/protogen_conf.json"

    p "running command #{command} :"
    output = `#{command} 2>&1`

    exit_code = $?.clone.exitstatus

    puts "Protogen output:\n #{output}\n\n"

    puts "Protogen exit code: #{exit_code}"

    if exit_code != 0 # non-zero exit code means error. We abort on all errors except code 4 and 5
      # see protocol_generator/error.rb for the signification of error codes
      puts "Protogen returned non-zero status code (non-zero status code means an error occured)."
      if exit_code == 4  # protocol file not found
        puts "Protocol file not found for #{agent_name} at 'config/protogen.json', Protogen will not be available for this agent."
      elsif exit_code == 5 # protocol file empty
        puts "Protocol file empty for #{agent_name} at 'config/protogen.json', Protogen will not be available for this agent."
      else
        puts "Protogen fatal error, see Protogen output for details."
        #PUNK.end('a','ko','',"SERVER Protogen generation for agent #{agent} failed")
        raise "Protogen generation failed for agent #{agent_name}"
      end
    else # success
      protogen_apis_to_include << "require_relative 'protogen_#{agent_name}/protogen_apis'"
    end

    puts "Protogen generation for #{agent_name} done."
    #PUNK.end('a','ok','',"SERVER generated Protogen for agent #{agent}")

    # copy documentation
    #FileUtils.mkdir_p("#{workspace_path}/#{agent}/doc/protogen")
    #FileUtils.cp_r(Dir["#{source_path}/cloud_agents_generated/protogen_#{agent}/doc/*"],"#{workspace_path}/#{agent}/doc/protogen/")
    puts "Protogen doc deployed for #{agent_name} \n"
  end # each agent
end # Bundler with clean env


#write include file
File.open("#{agents_generated_path}/protogen_generated.rb", 'w') { |file| file.write(protogen_apis_to_include.join("\n"))}

#write additionnal_info
File.open("#{agents_generated_path}/gen_additional_info.json", 'w') { |file| file.write(additionnal_info)}
