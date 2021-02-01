FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt install -y -qq git wget \
  mtools ovmf dmidecode python3-usb python3-pyudev pulseaudio jq \
  git libfdt-dev libpixman-1-dev libssl-dev vim socat libsdl2-dev \
  libspice-server-dev autoconf libtool xtightvncviewer tightvncserver \
  x11vnc uuid-runtime uuid uml-utilities bridge-utils python-dev liblzma-dev \
  libc6-dev libegl1-mesa-dev libepoxy-dev libdrm-dev libgbm-dev libaio-dev \
  libusb-1.0.0-dev libgtk-3-dev bison libcap-dev libattr1-dev flex \
  uuid-dev nasm acpidump iasl libelf-dev \
  kernel-package liblz4-tool rsync

ARG cwd
WORKDIR $cwd
ENTRYPOINT ["sh", "-c", "$profiledir/gvtg.sh"]
