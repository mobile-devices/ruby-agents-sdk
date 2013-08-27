#!/bin/bash

#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

command=$1
params=${@:2}

is_running_process() {
  return $(ps -ef | grep "$1" | grep -v "grep" | wc -l)
}

stop() {
  pkill -f 'ruby local_cloud.rb'
}

restart() {
  stop
  sync;sync;sync

  echo "restart local_cloud from sh" >>  ../../logs/daemon_server.log

  # gen gemms
  ruby gen_gemFile.rb >> ../../logs/daemon_server.log 2>&1
  if [ "$?" -ne 0 ] ; then
    echo 'PUNKabeNK_sys_merge gemfile' >>  ../../logs/ruby-agent-sdk-server.log
    echo "I, [XXXX-XX-XXT$(date +"%T").XXXXX #XXXXX] PUNKabe_sys_axd_{"type":"ko", "way":"", "title":"SERVER merge gemfile fail"}" >>  ../../logs/ruby-agent-sdk-server.log
    exit 1
  fi

  # install them
  echo 'PUNKabeNK_sys_bundle gem install' >>  ../../logs/ruby-agent-sdk-server.log
  bundle install >> ../../logs/ruby-agent-sdk-server.log 2>&1
  if [ "$?" -ne 0 ] ; then
      echo "I, [XXXX-XX-XXT$(date +"%T").XXXXX #XXXXX] PUNKabe_sys_axd_{"type":"ko", "way":"", "title":"SERVER ruby gems bundle install fail"}" >>  ../../logs/ruby-agent-sdk-server.log
    exit 1
  fi
  echo "I, [XXXX-XX-XXT$(date +"%T").XXXXX #XXXXX] PUNKabe_sys_axd_{\"type\":\"ok\", \"way\":\"\", \"title\":\"SERVER ruby gems bundle install done\"}" >>  ../../logs/ruby-agent-sdk-server.log

  echo "PUNKabeNK_sys_booting server" >>  ../../logs/ruby-agent-sdk-server.log
  # run sinatra server
  ruby local_cloud.rb >>../../logs/daemon_server.log 2>&1 &
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