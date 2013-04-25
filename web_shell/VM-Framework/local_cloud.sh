#!/bin/bash
command=$1
params=${@:2}

stop() {
  for id in `ps -ef | grep -i -e 'ruby local_cloud.rb' | awk '{ print $2 }'`; do
    echo "killing pid $id"
    kill -9 $id
  done
}

restart() {
  stop
  ruby local_cloud.rb -p 5001 > local_cloud.log &
}

$command $params