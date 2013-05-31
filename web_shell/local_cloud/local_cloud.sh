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