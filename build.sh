#!/bin/bash -e
mkdir -p $HOME/live/chroot
echo "Building docker container id..."
docker build -t debian-intrap . &> /dev/null
CID=$(docker create debian-intrap)
echo "Extract the docker container id export..."
docker export $CID | tar -xf- -C $HOME/live/chroot &> /dev/null
cd $HOME/live
mkdir -p $HOME/live/prod/{EFI/boot,boot/grub/x86_64-efi,isolinux,live}
echo "Compressing chroot and printing filesystem size..."
mksquashfs chroot prod/live/filesystem.squashfs
printf $(sudo du -sx --block-size=1 chroot | cut -f1) > prod/live/filesystem.size
