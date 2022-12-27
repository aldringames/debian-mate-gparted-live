#!/bin/bash -e
docker build -t debian-intrap .
mkdir -p $HOME/live/chroot
CID=(docker create debian-intrap)
docker export $CID | sudo tar -xf- -C $HOME/live/chroot
