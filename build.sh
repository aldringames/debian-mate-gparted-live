#!/bin/bash -e
WORK=$HOME/work/debian-mate-gparted-live/debian-mate-gparted-live
mkdir -p $HOME/live/chroot
echo "Building docker container id..."
docker build -t debian-intrap . &> /dev/null
CID=$(docker create debian-intrap)
echo "Extracting files from docker container id export..."
docker export $CID | tar -xf- -C $HOME/live/chroot &> /dev/null
sudo apt-get install -qqy squashfs-tools xorriso isolinux syslinux-common grub-pc-bin grub-efi-amd64-bin mtools dosfstools
cd $HOME/live
mkdir -p $HOME/live/prod/{EFI/boot,boot/grub/x86_64-efi,live}
echo "Copying override.conf to chroot/etc/systemd/system/getty@tty1.service.d/..."
mkdir -p chroot/etc/systemd/system/getty@tty1.service.d
cp -f $WORK/override.conf chroot/etc/systemd/system/getty@tty1.service.d/
echo "Creating hostnane as intrap..."
echo "intrap" > chroot/etc/hostname
echo "Copying hosts to chroot/etc/..."
cp $WORK/hosts chroot/etc/hosts
for file in bash_profile xinitrc; do
	echo "Copying $file to chroot/root/..."
	cp -f $WORK/$file chroot/root/.$file
done
touch prod/debian
echo "Compressing filesystem and printing fs size from chroot..."
mksquashfs chroot prod/live/filesystem.squashfs &> /dev/null
printf $(sudo du -sx --block-size=1 chroot | cut -f1) > prod/live/filesystem.size
echo "Converting Arial font to pf2 as grub font..."
grub-mkfont -o prod/live/arial.pf2 -s 15 $WORK/arial.ttf &> /dev/null
echo "Copying splash.png to prod/live/..."
cp $WORK/splash.png prod/live/
sudo chroot chroot
