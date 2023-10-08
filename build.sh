#!/bin/bash

set -eE 
trap 'echo Error: in $0 on line $LINENO' ERR

if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

cd "$(dirname -- "$(readlink -f -- "$0")")" && cd ..
mkdir -p build && cd build

# if [[ "${MAINLINE}" != "Y" ]]; then
#     test -d linux-rockchip || git clone --single-branch --progress -b turing-rk1 https://github.com/Joshua-Riek/linux-rockchip.git linux-rockchip
#     cd linux-rockchip

#     # Compile kernel into a deb package
#     dpkg-buildpackage -a "$(cat debian/arch)" -d -b -nc -uc

#     rm -f ../*.buildinfo ../*.changes
# else
    test -d linux ||  git clone --single-branch --progress -b v6.6-rc4-rk3588 https://github.com/Joshua-Riek/linux.git --depth=100

    test -d zfs || git clone --single-branch --progress -b zfs-2.2-release https://github.com/openzfs/zfs.git --depth=100

    cd zfs
    ./autogen.sh
    ./configure --enable-linux-builtin --with-linux=../linux/
    ./copy-builtin ../linux/
    cd linux

    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- rockchip_linux_defconfig
    sed -i 's/# CONFIG_ZFS is not set/CONFIG_ZFS=y/' .config
    make KERNELRELEASE="$(make kernelversion)" KBUILD_IMAGE="arch/arm64/boot/Image" CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 -j "$(nproc)" bindeb-pkg

    rm -f ../linux-image-*dbg*.deb ../linux-libc-dev_*.deb ../*.buildinfo ../*.changes ../*.dsc ../*.tar.gz
# fi