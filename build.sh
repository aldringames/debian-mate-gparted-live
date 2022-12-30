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
echo "Creating hostname as intrap..."
echo "intrap" > chroot/etc/hostname
echo "Copying hosts to chroot/etc/..."
cp $WORK/hosts chroot/etc/hosts
for file in bash_profile xinitrc; do
	echo "Copying $file to chroot/root/..."
	cp -f $WORK/$file chroot/root/.$file
done
echo "Creating resolv.conf to chroot/etc/..."
cat << EOF > chroot/etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 4.4.4.4
EOF
echo "Copying ocs-memtester to chroot/sbin/..."
cp $WORK/ocs-memtester chroot/sbin/
echo "Compressing filesystem and printing fs size from chroot..."
mksquashfs chroot prod/live/filesystem.squashfs &> /dev/null
printf $(sudo du -sx --block-size=1 chroot | cut -f1) > prod/live/filesystem.size
echo "Moving filesystem.packages to prod/live/..."
mv chroot/filesystem.packages prod/live/
echo "Converting Arial font to pf2 as grub font..."
grub-mkfont -o prod/live/arial.pf2 -s 15 $WORK/arial.ttf &> /dev/null
echo "Copying splash.png to prod/live/..."
cp $WORK/splash.png prod/live/
echo "Copying vmlinuz and initrd to prod/live/..."
cp chroot/boot/vmlinuz-* prod/live/vmlinuz
cp chroot/boot/initrd.img-* prod/live/initrd
echo "Downloading UEFI Shell to prod/live/..."
wget -qO prod/live/shellx64.efi https://github.com/retrage/edk2-nightly/raw/master/bin/RELEASEX64_Shell.efi
echo "Preparing to clone memtest86+ repository..."
git clone --depth=1 https://github.com/memtest86plus/memtest86plus.git &> /dev/null
echo "Building memtest86+ binaries..."
make -C memtest86plus/build64 -j$(nproc) all &> /dev/null
echo "Copying memtest86+ binaries to prod/live/..."
cp memtest86plus/build64/memtest.bin prod/live/memtest86+
cp memtest86plus/build64/memtest.efi prod/live/memtest86+.efi
echo "Copying boot configs..."
cp $WORK/grub.cfg $HOME/live/prod/boot/grub/
cp $WORK/grub.cfg $HOME/live/tmp/
cp $WORK/isolinux.cfg $HOME/live/prod/isolinux/
echo "Copying boot images..."
cp /usr/lib/ISOLINUX/isolinux.bin $HOME/live/prod/isolinux/
cp /usr/lib/syslinux/modules/bios/*  $HOME/live/prod/isolinux/
cp -r /usr/lib/grub/x86_64-efi/* $HOME/live/prod/boot/grub/x86_64-efi/
echo "Creating files for GRUB UEFI..."
cd $HOME/live/prod/EFI/boot/
grub-mkstandalone --format=x86_64-efi \
	          --output=$HOME/live/tmp/BOOTX64.efi \
		  --locales="" \
		  --fonts="" \
		  "boot/grub/grub.cfg=$HOME/live/tmp/grub.cfg"
dd if=/dev/zero of=efiboot.img bs=1M count=10 &> /dev/null
mkfs.vfat efiboot.img &> /dev/null
mmd -i efiboot.img efi efi/boot
mcopy -vi efiboot.img $HOME/live/tmp/BOOTX64.efi ::efi/boot/ &> /dev/null
_date="$(date +%Y%m%d_%H:%M)"
echo "Creating ISO, please it may take a while..."
cd $HOME/live/
xorriso \
    -as mkisofs \
    -iso-level 3 \
    -o "$HOME/live/debian-mate-gparted-live-${_datestamp}.iso" \
    -full-iso9660-filenames \
    -volid "Debian MATE GParted Live" \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -eltorito-boot \
        isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog isolinux/isolinux.cat \
    -eltorito-alt-boot \
        -e /EFI/boot/efiboot.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
    -append_partition 2 0xef $HOME/live/prod/EFI/boot/efiboot.img \
    "$HOME/live/prod/" &> /dev/null
echo "Copying ISO to the output/..."
mkdir $HOME/live/output
chmod +x $HOME/live/debian-mate-gparted-live-${_date}.iso
cp $HOME/live/debian-mate-gparted-live-${_date}.iso output/
sha256sum $HOME/live/debian-mate-gparted-live-${_date}.iso > output/debian-mate-gparted-live-${_date}.iso.sha256
md5sum $HOME/live/debian-mate-gparted-live-${_date}.iso > output/debian-mate-gparted-live-${_date}.iso.md5
echo "Cleaning chroot files..."
rm -rf chroot
echo "DATE=$(date +%Y%m%d)" >> $GITHUB_ENV
