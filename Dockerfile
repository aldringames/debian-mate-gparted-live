FROM debian:sid

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -qqy && \
  apt-get upgrade -qqy && \
  apt-get install -qqy \
    apt-utils \
    file \
    ca-certificates \
    tzdata \
    locales \
    uuid-runtime \
    curl \
    wget \
    network-manager && \
  sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
  dpkg-reconfigure --frontend=noninteractive locales && \
  update-locale LANG=en_US.UTF-8 && \
  touch /etc/netplan && \
  dpkg-reconfigure network-manager

RUN export LANG=en_US && \
  export LC_ALL=en_US.UTF-8

RUN apt-get install -qqy \
    mate-desktop-environment \
    mate-desktop-environment-extras \
    xorg \
    xinit \
    gparted \
    live-boot \
    epiphany-browser \
    systemd-sysv \
    emacs \
    geany \
    bash-completion \
    cifs-utils \
    dbus-x11 \
    dosfstools \
    firmware-linux-free \
    gddrescue \
    fdisk \
    gdisk \
    iputils-ping \
    isc-dhcp-client \
    less \
    nfs-common \
    ntfs-3g \
    openssh-client \
    open-vm-tools \
    procps \
    vim-gtk3 \
    wimtools \
    nano \
    wpagui \
    memtester \
    cpu-x \
    gnome-disk-utility \
    network-manager-gnome \
    p7zip-full \
    pv \
    cgpt \
    initramfs-tools && \
  apt-get install -qqy --no-install-recommends linux-image-amd64 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN rm /etc/resolv.conf && \
  ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

RUN rm /etc/machine-id && \
  dpkg --get-selections | tee /filesystem.packages
