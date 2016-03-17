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

RELEASE="15.05"
IMGTEMPDIR="${BUILD}/openwrt-build-image-extras"
IMGBUILDERDIR="${BUILD}/OpenWrt-ImageBuilder-${RELEASE}-ar71xx-generic.Linux-x86_64"
IMGBUILDERARCHIVE="OpenWrt-ImageBuilder-${RELEASE}-ar71xx-generic.Linux-x86_64.tar.bz2"
IMGBUILDERURL="https://downloads.openwrt.org/chaos_calmer/${RELEASE}/ar71xx/generic/${IMGBUILDERARCHIVE}"

# the absolute minimum for extroot to work at all (i.e. when the disk is already set up, for example by hand).
# this list may be smaller and/or different for your router, but it works with my ar71xx.
PREINSTALLED_PACKAGES="block-mount kmod-usb2 kmod-usb-storage kmod-fs-ext4"

# some kernel modules may also be needed for your hardware
#PREINSTALLED_PACKAGES+=" kmod-usb-uhci kmod-usb-ohci"

# these are needed for the proper functioning of the auto extroot scripts
PREINSTALLED_PACKAGES+=" blkid mount-utils swap-utils e2fsprogs fdisk"

# the following packages are optional, feel free to (un)comment them
PREINSTALLED_PACKAGES+=" wireless-tools firewall iptables"
PREINSTALLED_PACKAGES+=" kmod-usb-storage-extras kmod-mmc"
PREINSTALLED_PACKAGES+=" ppp ppp-mod-pppoe ppp-mod-pppol2tp ppp-mod-pptp kmod-ppp kmod-pppoe"
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
    tar jvxf ${IMGBUILDERARCHIVE}
    popd
fi

pushd ${IMGBUILDERDIR}

make image PROFILE=${TARGET_PLATFORM} PACKAGES="${PREINSTALLED_PACKAGES}" FILES=${IMGTEMPDIR}

pushd bin/ar71xx/
ln -s ../../packages .
popd

popd
