#!/bin/sh -e
_dimension=`xdpyinfo | grep "dimensions" | awk '{ print $2 }'`
xrandr -s ${_dimension}
mate-session
