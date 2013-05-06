#!/bin/bash
command=$1
params=${@:2}

restart() {
  pkill -f 'ruby local_cloud.rb'
  ruby local_cloud.rb >>../../logs/daemon_server.log 2>&1 &
}

$command $params