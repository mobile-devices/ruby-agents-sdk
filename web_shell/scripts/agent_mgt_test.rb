#!/usr/bin/ruby -w
require_relative 'agents_mgt'
require 'json'


add_agent_to_run_list('agps_agent')




cnf = Hash.new()
cnf['available_agents'] = get_available_agents()

p get_available_agents().to_json

p "+================================================================="
p "| available agents = [#{get_available_agents().join(';')}]"
p "| available agents = #{cnf.to_json()}"
p "| run agents = [#{get_run_agents().join(';')}]"
p "+================================================================="



p generate_new_guid


add_agent_to_run_list('norg_agent')


create_new_agent('norg_agent')



generate_agents()

