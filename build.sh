#!/bin/bash -e
sudo mkdir /chroot
sudo docker build -t debian-intrap .
sudo docker cp debian-intrap:/* /chroot/
