#!/bin/bash

name=gvtg-bin
cwd=$(pwd)
work_dir=./build
kdir="kernel"
krevision="3.0"
kversion="vt-sharing-ubuntu"
repo="https://github.com/intel/linux-intel-lts"
branch="5.4/yocto"
srcrev="e54641516247a77adbc3c314ddf1f7e8f7cc2787"
qemu_rel=qemu-4.2.0
qemu_dir=${qemu_rel}
prebuilt="prebuilt"
DEBIAN_FRONT=noninteractive

function create_output_dir() {
  mkdir -p ${work_dir}
  mkdir -p ${work_dir}/${prebuilt}
}

function pull_qemu_patches() {
  cd $work_dir
  wget -q https://raw.githubusercontent.com/projectceladon/vendor-intel-utils/master/host/qemu/0001-Revert-Revert-vfio-pci-quirks.c-Disable-stolen-memor.patch
  wget -q https://raw.githubusercontent.com/projectceladon/vendor-intel-utils/master/host/qemu/Disable-EDID-auto-generation-in-QEMU.patch
  wget -q https://raw.githubusercontent.com/projectceladon/vendor-intel-utils/master/host/ovmf/OvmfPkg-add-IgdAssgingmentDxe-for-qemu-4_2_0.patch
  cd $cwd
}

function build_qemu_bin() {
  wget https://download.qemu.org/$qemu_rel.tar.xz -P $work_dir
  cd $work_dir
  tar -xf $qemu_rel.tar.xz
  cd $qemu_rel/
  patch --verbose -p1 < ../Disable-EDID-auto-generation-in-QEMU.patch
  patch --verbose -p1 < ../0001-Revert-Revert-vfio-pci-quirks.c-Disable-stolen-memor.patch
  mkdir -p output
  echo "Building Qemu"
  ./configure --prefix=output \
          --enable-kvm \
          --disable-xen \
          --enable-libusb \
          --enable-debug-info \
          --enable-debug \
          --enable-sdl \
          --enable-vhost-net \
          --enable-spice \
          --disable-debug-tcg \
          --enable-opengl \
          --enable-gtk \
          --enable-virtfs \
          --target-list=x86_64-softmmu \
          --audio-drv-list=pa \
    >> build.out 2>&1
  make --silent -j$(nproc) >> build.out 2>&1
  make --silent -j$(nproc) install >> build.out 2>&1
  cd $cwd
}

function create_qemu_package() {
  cd ${work_dir}/${qemu_dir}/output
  tar cvf qemu.tar.gz *
  cd $cwd 
}

function build_qemu() {
  pull_qemu_patches
  build_qemu_bin
  create_qemu_package
}

function pull_kernel() {
  [[ ! -d "$work_dir/$kdir" ]] && git clone $repo --branch $branch --single-branch $work_dir/$kdir && cd $work_dir/$kdir; git checkout $srcrev && cd $cwd
}

function kernel_config() {
  ( cd $work_dir/$kdir && echo "" | make oldconfig && cd $cwd)
}

function compile_kernel() {
  ( cd $work_dir/$kdir && CONCURRENCY_LEVEL=`nproc` fakeroot make-kpkg -j`nproc` --initrd --append-to-version=-$kversion --revision $krevision --overlay-dir=ubuntu-package kernel_image kernel_headers && cd $cwd)
}

function build_kernel() {
  pull_kernel
  kernel_config
  compile_kernel
}

function copy_binaries() {
  cp $work_dir/$qemu_dir/output/qemu.tar.gz $work_dir/$prebuilt/
  cp $work_dir/linux-headers-* $work_dir/$prebuilt/
  cp $work_dir/linux-image-* $work_dir/$prebuilt/
  (cd $work_dir/$prebuilt && chmod 777 * && cd -)
  (cd $work_dir && rm -rf *.deb *.patch qemu* kernel && cd -)
}

function run() {
  create_output_dir
  build_qemu
  build_kernel
  copy_binaries
}

run
