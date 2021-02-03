#!/bin/bash

# Copyright (C) 2019 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause

set -a

#this is provided while using Utility OS
source /opt/bootstrap/functions

# --- Config
KERNEL_VER="5.4.73-vt-sharing-ubuntu_3.0"
ubuntu_bundles="ubuntu-desktop openssh-server"
ubuntu_packages="net-tools vim software-properties-common apt-transport-https wget libspice-server-dev libsdl2-2.0-0 libaio-dev"

param_httpserver=$1

# --- Install Extra Packages ---
run "Installing Extra Packages on Ubuntu ${param_ubuntuversion}" \
    "docker run -i --rm --privileged --name ubuntu-installer ${DOCKER_PROXY_ENV} -v /dev:/dev -v /sys/:/sys/ -v $ROOTFS:/target/root ubuntu:${param_ubuntuversion} sh -c \
    'mount --bind dev /target/root/dev && \
    mount -t proc proc /target/root/proc && \
    mount -t sysfs sysfs /target/root/sys && \
    LANG=C.UTF-8 chroot /target/root sh -c \
    \"$(echo ${INLINE_PROXY} | sed "s#'#\\\\\"#g") export TERM=xterm-color && \
    mount ${BOOT_PARTITION} /boot && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt install -y tasksel && \
    tasksel install ${ubuntu_bundles} && \
    apt install -y ${ubuntu_packages} && \
    wget --header \\\"Authorization: token ${param_token}\\\" http://${param_httpserver}/tftp/images/gvtg-bin/prebuilt/linux-image-${KERNEL_VER}_amd64.deb && \
    wget --header \\\"Authorization: token ${param_token}\\\" http://${param_httpserver}/tftp/images/gvtg-bin/prebuilt/linux-headers-${KERNEL_VER}_amd64.deb && \
    dpkg -i linux-image-${KERNEL_VER}_amd64.deb && \
    dpkg -i linux-headers-${KERNEL_VER}_amd64.deb && \
    update-grub\"'" \
    ${PROVISION_LOG}

# --- Install qemu files ---
run "Installing qemu on Ubuntu ${param_bootstrapurl} " \
    "wget http://${param_httpserver}/tftp/images/gvtg-bin/prebuilt/qemu.tar.gz -P ${ROOTFS}/usr && \
     tar xvf ${ROOTFS}/usr/qemu.tar.gz -C ${ROOTFS}/usr && \
     rm ${ROOTFS}/usr/qemu.tar.gz " \
    ${PROVISION_LOG}


# --- Install seabios files ---
run "Installing seabios on Ubuntu ${param_bootstrapurl} " \
    "wget http://${param_httpserver}/tftp/images/gvtg-bin/prebuilt/seabios.tar.gz -P ${ROOTFS}/usr && \
     tar xvf ${ROOTFS}/usr/seabios.tar.gz -C ${ROOTFS}/usr/share/firmware && \
     rm ${ROOTFS}/usr/seabios.tar.gz " \
    ${PROVISION_LOG}

# --- Install edk files ---
run "Installing edk on Ubuntu ${param_bootstrapurl} " \
    "wget http://${param_httpserver}/tftp/images/gvtg-bin/prebuilt/edk.tar.gz -P ${ROOTFS}/usr && \
     tar xvf ${ROOTFS}/usr/edk.tar.gz -C ${ROOTFS}/usr/ && \
     rm ${ROOTFS}/usr/edk.tar.gz " \
    ${PROVISION_LOG}

