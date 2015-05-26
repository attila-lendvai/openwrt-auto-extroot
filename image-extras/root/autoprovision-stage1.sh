#!/bin/sh

# autoprovision stage 1: this script will be executed upon boot without a valid extroot (i.e. when rc.local is found and run from the internal overlay)

. /root/autoprovision-functions.sh

getPendriveSize()
{
    # this is needed for the mmc card in some (all?) Huawei 3G dongle.
    # details: https://dev.openwrt.org/ticket/10716#comment:4
    if [ -e /dev/sda ]; then
        # force re-read of the partition table
        head /dev/sda >/dev/null
    fi

    if (grep -q sda /proc/partitions) then
        cat /sys/block/sda/size
    else
        echo 0
    fi
}

hasBigEnoughPendrive()
{
    local size=$(getPendriveSize)
    if [ $size -ge 600000 ]; then
        log "Found a pendrive of size: $(($size / 2 / 1024)) MB"
        return 0
    else
        return 1
    fi
}

setupPendrivePartitions()
{
    # erase partition table
    dd if=/dev/zero of=/dev/sda bs=1M count=1

    # sda1 is 'swap'
    # sda2 is 'root'
    # sda3 is 'data'
    fdisk /dev/sda <<EOF
o
n
p
1

+64M
n
p
2

+512M
n
p
3


t
1
82
w
q
EOF
    log "Finished partitioning /dev/sda using fdisk"

    sleep 2

    until [ -e /dev/sda1 ]
    do
        echo "Waiting for partitions to show up in /dev"
        sleep 1
    done

    mkswap -L swap -U $swapUUID /dev/sda1
    mkfs.ext4 -L root -U $rootUUID /dev/sda2
    mkfs.ext4 -L data -U $dataUUID /dev/sda3

    log "Finished setting up filesystems"
}

setupExtroot()
{
    mkdir -p /mnt/extroot
    # TODO they said on the wiki that it's optional, an empty overlay also works...
    # we need to make the internal overlay read-only, otherwise the two md5's may be different
    # due to writing to the internal overlay from this point until the reboot.
    # files: /.extroot.md5sum (extroot) and /etc/extroot.md5sum (internal)
    #mount -o remount,ro /
    #log "Remounted / as read-only"

    mount -U $rootUUID /mnt/extroot
    #tar -C /overlay -cvf - . | tar -C /mnt/extroot -xf -

    # let's write a new rc.local on extroot which will shadow the one which is in the rom and runs stage1
    mkdir -p /mnt/extroot/etc/
    cat >/mnt/extroot/etc/rc.local <<EOF
/root/autoprovision-stage2.sh
exit 0
EOF

    # make sure that we shadow the /var -> /tmp symlink with the extroot, so that /var is permanent
    mkdir -p /mnt/extroot/var
    # KLUDGE: but /var/state is assumed to be transient, see https://dev.openwrt.org/ticket/12228
    cd /mnt/extroot/var
    ln -s /tmp state
    cd -

    log "Finished setting up extroot"
}

autoprovisionStage1()
{
    signalAutoprovisionWorking

    signalAutoprovisionWaitingForUser
    signalWaitingForPendrive

    until hasBigEnoughPendrive
    do
        echo "Waiting for a pendrive to be inserted"
        sleep 3
    done

    signalAutoprovisionWorking # to make it flash in sync with the USB led
    signalFormatting

    sleep 1

    setupPendrivePartitions
    sleep 1
    setupExtroot

    sync
    stopSignallingAnything
    reboot
}

autoprovisionStage1
