#!/bin/bash
command=$1
params=${@:2}

restart() {
  killall 'ruby local_cloud.rb'
  ruby local_cloud.rb >>../../logs/local_cloud.ruby.log 2>&1 &
}

$command $params