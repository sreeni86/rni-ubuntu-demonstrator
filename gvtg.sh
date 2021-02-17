#!/bin/bash

name=gvtg-bin
cwd=$(pwd)
work_dir=data/srv/tftp/images/${name}
kdir="kernel"
krevision="3.0"
kversion="vt-sharing-ubuntu"
repo="https://github.com/intel/linux-intel-lts"
branch="5.4/yocto"
srcrev="e54641516247a77adbc3c314ddf1f7e8f7cc2787"
kernel_config_url="https://kernel.ubuntu.com/~kernel-ppa/config/focal/linux/5.4.0-44.48/amd64-config.flavour.generic"
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

function build_seabios_bin() {
  cd $cwd
  cd $work_dir
  git clone https://github.com/coreboot/seabios.git           
  cd seabios
  make
  ls -l out/bios.bin
}

function create_seabios_package() {
  cd $cwd
  cd ${work_dir}/seabios/out
  tar cvf seabios.tar.gz bios.bin
  cd $cwd 
}

function build_seabios() {
  build_seabios_bin
  create_seabios_package
}

function build_edk_bin() {
  cd $cwd
  cd $work_dir
  git clone https://github.com/tianocore/edk2
  cd edk2
  git submodule update --init
  make -C BaseTools
  . edksetup.sh 
  build -b RELEASE -t GCC5 -a X64 -p OvmfPkg/OvmfPkgX64.dsc -D NETWORK_IP4_ENABLE -D NETWORK_ENABLE
}

function create_edk_package() {
  cd $cwd
  cd ${work_dir}/edk2/Build/OvmfX64/RELEASE_GCC5/FV/
  tar cvf edk.tar.gz OVMF_CODE.fd OVMF_VARS.fd
  cd $cwd 
}

function build_edk() {
  build_edk_bin
  create_edk_package
}

function pull_kernel() {
  [[ ! -d "$work_dir/$kdir" ]] && git clone $repo --branch $branch --single-branch $work_dir/$kdir && cd $work_dir/$kdir; git checkout $srcrev && cd $cwd
}

function kernel_config() {
  if [ ! -z "$kernel_config_url" ]; then
    /usr/bin/wget -q -O $work_dir/$kdir/.config $kernel_config_url
  fi

  ( cd $work_dir/$kdir && yes "" | make oldconfig && cd $cwd)
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
  cp $work_dir/seabios/out/seabios.tar.gz $work_dir/$prebuilt/
  cp $work_dir/edk2/Build/OvmfX64/RELEASE_GCC5/FV/edk.tar.gz $work_dir/$prebuilt/
  cp $work_dir/linux-headers-* $work_dir/$prebuilt/
  cp $work_dir/linux-image-* $work_dir/$prebuilt/
  (cd $work_dir/$prebuilt && chmod 777 * && cd -)
  (cd $work_dir && rm -rf *.deb *.patch qemu* kernel && cd -)
}

function run() {
  create_output_dir
  build_qemu
  build_seabios
  build_edk
  build_kernel
  copy_binaries
}

run
