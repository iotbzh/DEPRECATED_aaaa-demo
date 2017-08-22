#!/bin/bash

# -------------------------------------------------------------------
#  Start a Stand Alone Controler to Server AAAADemo HTML5
#
#  Requirement:
#    mpdc started with --ws-server:/var/tmp/afb-ws/mpdc
#    aaaa started with --ws-server:/var/tmp/afb-ws/control
# -------------------------------------------------------------------

# FIXME - temporary hack to create playlist manually
# Load default playlists
MPD_PORT=6601 mpc clear
MPD_PORT=6601 mpc load default
MPD_PORT=6602 mpc clear
MPD_PORT=6602 mpc load default
MPD_PORT=6603 mpc clear
MPD_PORT=6603 mpc load default


# BUG CONTROL_xxx_PATH should be absolute
DEMOPATH=$PWD/`dirname $0`

# Demo TCP port for HTML apps
  DEMO_PORT=1235

# Service Unix Websocket Path
  WS_BINDIND_PATH=/var/tmp/afb-ws
  MPDC_SOCK=unix:$WS_BINDIND_PATH/mpdc
  AAAA_SOCK=unix:$WS_BINDIND_PATH/control

# Lua compiler (On Unbutu name is lua53)
  LUAC=lua5.3

# Audio-Demo local path
  export CONTROL_CONFIG_PATH=$DEMOPATH/conf.d/project/json.d
  export CONTROL_LUA_PATH=$DEMOPATH/conf.d/project/lua.d
  export AFB_BINDER_NAME=AAAAdemo


# Fulup OpenSuse Home Config
  if [ $HOSTNAME = fulup-desktop ]; then
    RUN_FROM_DEV_TREE=true
    RUN_IN_GROUP=true

    AFB_DEBUG_OPTION="--tracereq=common --token= --verbose"

    CTL_HOMEDEV=$HOME/Workspace/AGL-AppFW/audio-bindings-dev
    MPDC_HOMEDEV=$HOME/Workspace/AGL-AppFW/mpdc-binding
  fi
  if [ $HOSTNAME = seb-laptop ]; then
    RUN_FROM_DEV_TREE=true
    RUN_IN_GROUP=true

    AFB_DEBUG_OPTION="--tracereq=common --token= --verbose"

    CTL_HOMEDEV=$HOME/Work/git/audio-bindings
    MPDC_HOMEDEV=$HOME/Work/git/mpdc-binding
  fi

# Default installation path
  INSTALL_PREFIX=$HOME/opt
  CTL_INSTALL=$INSTALL_PREFIX/audio-bindings
  MPDC_INSTALL=$INSTALL_PREFIX/mpdc-binding

# Do not try to connect on default MPD at init time
export MPDC_NODEF_CONNECT=1

# Select Dev or Installed binding
if [ $RUN_FROM_DEV_TREE = true ]; then
    CTL_BINDING=$CTL_HOMEDEV/build/Controller-afb/afb-control-afb.so
    MPDC_BINDING=$MPDC_HOMEDEV/build/afb-mpdclient/afb-mpdc-api.so
else
    CTL_BINDING=$CTL_INSTALL/afb-control-afb.so
    MPDC_BINDING=$CTL_INSTALL/afb-mpdc-api.so
fi


# check luac presence
LUA_VERSION=`$LUAC -v`
if test $? -ne 0; then
   echo "Command $LUAC not found please set \$LUA for your host"
   exit
fi

echo -------

# Compile lua script before starting the demo
for FILE in  $CONTROL_LUA_PATH/*.lua; do
    $LUAC $FILE -o /dev/null
    if test $? -ne 0; then
        echo " ERROR: Must fixe LUA error before starting your binder"
        echo -------
        exit
    fi
done


if [ $RUN_IN_GROUP = true ]; then
    AFB_DAEMON_CMD="afb-daemon --port=$DEMO_PORT  --ldpaths=/dev/null --binding=$CTL_BINDING --binding=$MPDC_BINDING \
    --workdir=$DEMOPATH --roothttp=./htdocs  $AFB_DEBUG_OPTION"
else

    if test ! -d $WS_BINDIND_PATH; then
        echo "  -- ERROR: AFB Websocket should exist. Request:$WS_BINDIND_PATH"
        exit
    fi

    AFB_DAEMON_CMD="afb-daemon --port=$DEMO_PORT  --ldpaths=/dev/null --binding=$CTL_BINDING \
    --workdir=$DEMOPATH --roothttp=./htdocs --ws-client=$MPDC_SOCK $AFB_DEBUG_OPTION"
fi
echo $AFB_DAEMON_CMD
echo ------------------------------------------------------------

exec $AFB_DAEMON_CMD
#gdbserver localhost:4444 $AFB_DAEMON_CMD

