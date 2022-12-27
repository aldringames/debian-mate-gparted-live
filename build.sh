#!/bin/bash -e
sudo mkdir /chroot
sudo docker build -t debian-intrap .
sudo docker run --name debian-intrap-dist debian-intrap
sudo docker cp debian-intrap-dist:/* /chroot/
