#!/bin/bash

#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

command=$1
params=${@:2}

# init paths
if [ "`echo $0 | cut -c1`" = "/" ]; then
  here_path=`dirname $0`
else
  here_path=`pwd`/`echo $0 | sed -e s/$_my_name//`
fi
ruby_log_path="$here_path../../logs/ruby-agent-sdk-server.log"
important_agent_path_path="$here_path/ragent_bay/builder"
daemon_log_path="$here_path../../logs/daemon_server.log"

echo "log_path=$ruby_log_path"

is_running_process() {
  return $(ps -ef | grep "$1" | grep -v "grep" | wc -l)
}

stop() {
  echo "stop local_cloud from sh" >>  $daemon_log_path
  pkill -f 'ruby local_cloud.rb'
}

import_agents() {
  nb_agents=$1
  shift;
  agents="$@"
  echo "import_agents  $agents local_cloud from sh"
  echo "import_agents $nb_agents: $agents local_cloud from sh" >>  $daemon_log_path
  #exit 1

  # call import agent
  echo 'PUNKabeNK_sys_importing agents' >>  $ruby_log_path
  cd $important_agent_path_path
  echo "bundle install"
  bundle install
  echo "bundle exec ruby import_agents.rb ../../Gemfile.master ../../Gemfile x $agents"
  bundle exec ruby import_agents.rb ../../Gemfile.master ../../Gemfile x $agents  >> $ruby_log_path 2>&1
  if [ "$?" -ne 0 ] ; then
    echo "I, [XXXX-XX-XXT$(date +"%T").XXXXX #XXXXX] PUNKabe_sys_axd_{\"type\":\"ko\", \"way\":\"\", \"title\":\"SERVER import agents fail\"}" >>  $ruby_log_path
    exit 1;
  fi;
  echo "I, [XXXX-XX-XXT$(date +"%T").XXXXX #XXXXX] PUNKabe_sys_axd_{\"type\":\"ok\", \"way\":\"\", \"title\":\"SERVER has import $nb_agents agents successfully\"}" >>  $ruby_log_path
}

start() {
  echo "start local_cloud from sh" >>  $daemon_log_path

  # install gems
  echo 'PUNKabeNK_sys_bundle gem install+update' >>  $ruby_log_path
  bundle install >> $ruby_log_path 2>&1
  if [ "$?" -ne 0 ] ; then
    echo "I, [XXXX-XX-XXT$(date +"%T").XXXXX #XXXXX] PUNKabe_sys_axd_{\"type\":\"ko\", \"way\":\"\", \"title\":\"SERVER ruby gems bundle install fail\"}" >>  $ruby_log_path
    exit 1
  fi
  echo "I, [XXXX-XX-XXT$(date +"%T").XXXXX #XXXXX] PUNKabe_sys_axd_{\"type\":\"ok\", \"way\":\"\", \"title\":\"SERVER ruby gems bundle install done\"}" >>  $ruby_log_path
  bundle update >> $ruby_log_path 2>&1
  if [ "$?" -ne 0 ] ; then
    echo "I, [XXXX-XX-XXT$(date +"%T").XXXXX #XXXXX] PUNKabe_sys_axd_{\"type\":\"ko\", \"way\":\"\", \"title\":\"SERVER ruby gems bundle update fail\"}" >>  $ruby_log_path
    exit 1
  fi
  echo "I, [XXXX-XX-XXT$(date +"%T").XXXXX #XXXXX] PUNKabe_sys_axd_{\"type\":\"ok\", \"way\":\"\", \"title\":\"SERVER ruby gems bundle update done\"}" >>  $ruby_log_path



  echo "PUNKabeNK_sys_booting server" >>  $ruby_log_path
  # run sinatra server
  bundle exec ruby local_cloud.rb >> $daemon_log_path 2>&1 &
}

is_running() {
  rm /tmp/local_cloud_running
  is_running_process 'ruby local_cloud.rb'

  if [ "$?" -ne 1 ] ; then
    echo -ne 'no' > /tmp/local_cloud_running
    exit 1
  fi
  echo -ne 'yes' > /tmp/local_cloud_running
}

$command $params