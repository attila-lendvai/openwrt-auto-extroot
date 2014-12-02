#!/bin/bash

absolutize ()
{
  if [ ! -d "$1" ]; then
    echo
    echo "ERROR: '$1' doesn't exist or not a directory!"
    exit -1
  fi

  pushd "$1" >/dev/null
  echo `pwd`
  popd >/dev/null
}

TARGET_PLATFORM=$1
BUILD=`dirname "$0"`"/build/"
BUILD=`absolutize $BUILD`
IMGTEMPDIR="${BUILD}/openwrt-build-image-extras"
IMGBUILDERDIR="${BUILD}/OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64"
IMGBUILDERURL="https://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64.tar.bz2"

mkdir --parents ${BUILD}

rm -rf $IMGTEMPDIR
cp -r image-extras $IMGTEMPDIR
if [ -e image-extras.$TARGET_PLATFORM/ ]; then
    rsync -pr image-extras.$TARGET_PLATFORM/ $IMGTEMPDIR/
fi

if [ ! -e ${IMGBUILDERDIR} ]; then
    pushd ${BUILD}
    wget --continue ${IMGBUILDERURL}
    tar jvxf OpenWrt-ImageBuilder*.tar.bz2
    popd
fi

pushd ${IMGBUILDERDIR}

make image PROFILE=$TARGET_PLATFORM PACKAGES="wireless-tools firewall iptables fdisk blkid block-mount e2fsprogs kmod-fs-ext4 kmod-usb2 kmod-usb-uhci kmod-usb-ohci kmod-usb-storage kmod-usb-storage-extras luci kmod-mmc mount-utils ppp ppp-mod-pppoe ppp-mod-pppol2tp ppp-mod-pptp kmod-ppp kmod-pppoe" FILES=${IMGTEMPDIR}

pushd bin/ar71xx/
ln -s ../../packages .
popd

popd
