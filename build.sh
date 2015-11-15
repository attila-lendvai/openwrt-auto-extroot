#!/bin/bash

set -e

absolutize ()
{
  if [ ! -d "$1" ]; then
    echo
    echo "ERROR: '$1' doesn't exist or not a directory!"
    kill -INT $$
  fi

  pushd "$1" >/dev/null
  echo `pwd`
  popd >/dev/null
}

TARGET_PLATFORM=$1

if [ -z ${TARGET_PLATFORM} ]; then
    echo "Usage: $0 target-platform (e.g. 'TLWDR4300')"
    kill -INT $$
fi

BUILD=`dirname "$0"`"/build/"
BUILD=`absolutize $BUILD`
IMGTEMPDIR="${BUILD}/openwrt-build-image-extras"
IMGBUILDERDIR="${BUILD}/OpenWrt-ImageBuilder-15.05-ar71xx-generic.Linux-x86_64"
IMGBUILDERURL="https://downloads.openwrt.org/chaos_calmer/15.05/ar71xx/generic/OpenWrt-ImageBuilder-15.05-ar71xx-generic.Linux-x86_64.tar.bz2"

# the minimally needed packages for the proper functioning of the auto extroot machinery.
# kmod-fs-ext4  225k
# e2fsprogs     182k
# fdisk         100k
# the rest are around 20-30k
PREINSTALLED_PACKAGES="blkid block-mount kmod-usb2 kmod-usb-storage mount-utils swap-utils e2fsprogs kmod-fs-ext4 fdisk"

# the following packages are optional, feel free to (un)comment them
PREINSTALLED_PACKAGES+=" wireless-tools firewall iptables"
PREINSTALLED_PACKAGES+=" kmod-usb-storage-extras kmod-mmc"
PREINSTALLED_PACKAGES+=" ppp ppp-mod-pppoe ppp-mod-pppol2tp ppp-mod-pptp kmod-ppp kmod-pppoe"
PREINSTALLED_PACKAGES+=" kmod-usb-uhci kmod-usb-ohci"
PREINSTALLED_PACKAGES+=" luci"

mkdir --parents ${BUILD}

rm -rf $IMGTEMPDIR
cp -r image-extras/common/ $IMGTEMPDIR
PER_PLATFORM_IMAGE_EXTRAS=image-extras/${TARGET_PLATFORM}/
if [ -e $PER_PLATFORM_IMAGE_EXTRAS ]; then
    rsync -pr $PER_PLATFORM_IMAGE_EXTRAS $IMGTEMPDIR/
fi

if [ ! -e ${IMGBUILDERDIR} ]; then
    pushd ${BUILD}
    wget --continue ${IMGBUILDERURL}
    tar jvxf OpenWrt-ImageBuilder*.tar.bz2
    popd
fi

pushd ${IMGBUILDERDIR}

make image PROFILE=${TARGET_PLATFORM} PACKAGES="${PREINSTALLED_PACKAGES}" FILES=${IMGTEMPDIR}

pushd bin/ar71xx/
ln -s ../../packages .
popd

popd
