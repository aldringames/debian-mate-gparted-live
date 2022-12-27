#!/bin/sh -e
xrandr -s `xdpyinfo | grep "dimensions" | awk '{ print $2 }'`
pulseaudio --start
pactl set-sink-volume 0 100%
mate-session
