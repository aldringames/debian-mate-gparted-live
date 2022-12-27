#!/bin/bash -e
sudo mkdir /chroot
sudo docker build -t debian-intrap .
CID=$(sudo docker create debian-intrap)
sudo docker export $CID | tar -xf- -C /chroot
