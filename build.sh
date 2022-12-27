#!/bin/bash -e
mkdir -p $HIME/live/chroot
docker build -t debian-intrap .
CID=(docker create debian-intrap)
docker export $CID | sudo tar -xf- -C $HOME/live/chroot
