#!/bin/bash -e
mkdir /chroot
docker build -t debian-intrap .
docker cp debian-intrap:/* /chroot/
