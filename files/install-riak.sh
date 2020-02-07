#!/bin/bash
set -e eu

source /lib/gentoo/functions.sh
source /etc/portage/make.conf

# Build riak
export GIT_BRANCH_RIAK=riak-2.9.0p5

cd /opt
git clone -n -b $GIT_BRANCH_RIAK https://github.com/basho/riak.git riak;
cd riak; git checkout -q $GIT_BRANCH_RIAK;
mv /riak-rebar.config /opt/riak/rebar.config
mv /riak-reltool.config /opt/riak/rel/reltool.config
mv /riak.schema /opt/riak/rel/files/riak.schema
make lock
make rel OVERLAY_VARS="overlay_vars=/vars.config"
