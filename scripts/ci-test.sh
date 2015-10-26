#!/bin/bash
set -eu

# The processes inherit the process group id from the leader, which is its PID
# http://unix.stackexchange.com/a/139230/18594
PGID=$$

function finish {
    if [ -n "${TRAVIS+1}" ]; then
      echo "TRAVIS detected, skip killing child processes"
    else
      # clean up xulrunner process from slimerjs, and any other remaining processes
      kill -- "-$PGID" 
    fi

}

trap finish SIGINT SIGTERM EXIT

echo
echo starting buster-server
./node_modules/buster/bin/buster-server & # fork to a subshell
sleep 4 # takes a while for buster server to start

echo
echo starting slimerjs
./node_modules/.bin/slimerjs --load-images=false ./node_modules/buster/script/phantom.js &
sleep 1 # give phantomjs a second to warm up

echo
echo "starting buster-test (source)"
./node_modules/buster/bin/buster-test --config-group coverage

echo
echo "starting buster-test (packaged)"
./build
./node_modules/buster/bin/buster-test --config test/buster-packaged.js
