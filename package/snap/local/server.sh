#!/bin/bash

CONFIG=$HOME/.config/vostok-web
PORT=$1
SUFFIX=$2
ACCESS=$3

if [ ! -f $CONFIG/workdir-local ]; then
    mkdir -p $CONFIG
    echo $HOME/vostok-web/local > $CONFIG/workdir-local
    echo $HOME/vostok-web/share > $CONFIG/workdir-share
fi
SAVES=`cat $CONFIG/workdir$SUFFIX`
mkdir -p "$SAVES"

openSite() {
    sleep 0.1
    xdg-open http://localhost:$PORT
}

MSG="config: $CONFIG\\nsaves: $SAVES"
echo -e "$MSG"
notify-send Vostok "$MSG"

openSite &

cd $SNAP/usr/share/vostok/server
echo $SNAP/usr/bin/server -workdir "$SAVES" -port $PORT $ACCESS
$SNAP/usr/bin/server -workdir "$SAVES" -port $PORT $ACCESS
