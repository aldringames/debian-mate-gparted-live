#!/bin/bash -e
WORK=$HOME/work/debian-mate-gparted-live/debian-mate-gparted-live
mkdir -p $HOME/live/chroot
echo "Building docker container id..."
docker build -t debian-intrap . &> /dev/null
CID=$(docker create debian-intrap)
echo "Extracting files from docker container id export..."
docker export $CID | tar -xf- -C $HOME/live/chroot &> /dev/null
echo "Install packages for making iso..."
sudo apt-get install -qqy squashfs-tools xorriso isolinux syslinux-common grub-pc-bin grub-efi-amd64-bin mtools dosfstools &> /dev/null
cd $HOME/live
mkdir -p $HOME/live/{prod/{EFI/boot,boot/grub/x86_64-efi,isolinux,live},tmp}
touch prod/debian
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
echo "Copying ocs-memtester to chroot/bin/..."
cp $WORK/ocs-memtester chroot/bin/
echo "Compressing filesystem and printing fs size from chroot..."
mksquashfs chroot prod/live/filesystem.squashfs &> /dev/null
printf $(sudo du -sx --block-size=1 chroot | cut -f1) > prod/live/filesystem.size
echo "Converting Arial font to pf2 as grub font..."
grub-mkfont -o prod/live/arial.pf2 -s 15 $WORK/arial.ttf &> /dev/null
echo "Copying splash.png to prod/live/..."
cp $WORK/splash.png prod/live/
echo "Copying vmlinuz and initrd to prod/live/..."
cp chroot/boot/vmlinuz-* prod/live/vmlinuz
cp chroot/boot/initrd.img-* prod/live/initrd
echo "Downloading UEFI Shell and copying to prod/live/..."
wget -qO prod/live/shellx64.efi https://github.com/retrage/edk2-nightly/raw/master/bin/RELEASEX64_Shell.efi
echo "Preparing to clone memtest86+ repository..."
git clone --depth=1 https://github.com/memtest86plus/memtest86plus.git &> /dev/null
echo "Building memtest86+ binaries..."
make -C memtest86plus/build64 -j$(nproc) all &> /dev/null
echo "Copying memtest86+ binaries to prod/live/..."
ls
ls memtest86plus
ls memtest86plus/build64
