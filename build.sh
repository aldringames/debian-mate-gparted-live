#!/bin/bash -e
mkdir -p $HOME/live/chroot
echo "Building docker container id..."
docker build -t debian-intrap . &> /dev/null
CID=$(docker create debian-intrap)
echo "Extract the docker container id export..."
docker export $CID | tar -xf- -C $HOME/live/chroot &> /dev/null
sudo apt-get install -qqy squashfs-tools xorriso isolinux syslinux-common grub-pc-bin grub-efi-amd64-bin mtools dosfstools
cd $HOME/live
mkdir -p $HOME/live/prod/{EFI/boot,boot/grub/x86_64-efi,live}
touch prod/debian
echo "Compressing filesystem and printing fs size from chroot..."
mksquashfs chroot prod/live/filesystem.squashfs &> /dev/null
printf $(sudo du -sx --block-size=1 chroot | cut -f1) > prod/live/filesystem.size
echo "Converting Arial font to pf2 as grub font..."
grub-mkfont -o prod/live/arial.pf2 -s 15 $HOME/debian-mate-gparted-live/arial.ttf &> /dev/null
cp $HOME/debian-mate-gparted-live/splash.png prod/live/
sudo chroot chroot
