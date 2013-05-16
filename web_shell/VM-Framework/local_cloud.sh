#!/bin/bash

#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

command=$1
params=${@:2}

stop() {
  pkill -f 'ruby local_cloud.rb'
}


restart() {
  stop
  ruby local_cloud.rb >>../../logs/daemon_server.log 2>&1 &
}

$command $params