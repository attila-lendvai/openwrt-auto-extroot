#!/bin/sh

# Array, compatible with sh
# This is the uuid of disk to be ignored
# when the wrong disk is assigned to /dev/sda
# more uuids can be added set -- "uuid" "uuid"
set -- "2aa93491-d111-4942-865a-be5ec8e2e9f4"

# utility functions for the various stages of autoprovisioning
# make sure that installed packages take precedence over busybox. see https://dev.openwrt.org/ticket/18523
PATH="/usr/bin:/usr/sbin:/bin:/sbin"

# these are also copy-pasted into other scripts and config files!
export rootUUID=05d615b3-bef8-460c-9a23-52db8d09e000
export dataUUID=05d615b3-bef8-460c-9a23-52db8d09e001
export swapUUID=05d615b3-bef8-460c-9a23-52db8d09e002

. /lib/functions.sh

# let's attempt to define some defaults...
autoprovisionUSBLed="green:usb"
autoprovisionStatusLed="green:qss"

log()
{
    /usr/bin/logger -t autoprov -s "${*}"
}

for device in "${@}"; do
    dev_path=$(blkid -U "${device}")
    if [ "/dev/sda" = "${dev_path}" ]; then
        logger "${dev_path}"
        sleep 10
        echo "Rebooting..."
        reboot
    fi
done

echo "Board name is [${board_name}]"

# CUSTOMIZE
case $(board_name) in
    *tl-wr1043nd*)
        autoprovisionUSBLed="green:usb"
        autoprovisionStatusLed="green:qss"
        ;;
    *tl-mr3020*)
        autoprovisionUSBLed="green:wps"
        autoprovisionStatusLed="green:wlan"
        ;;
    *tl-wr2543n*)
        autoprovisionUSBLed="green:wps"
        autoprovisionStatusLed="green:wlan5g"
        ;;
    *tl-wdr4300*)
        autoprovisionUSBLed="green:wlan2g"
        autoprovisionStatusLed="green:wlan5g"
        ;;
    *archer-c7-v1*)
        autoprovisionUSBLed="green:wlan2g"
        autoprovisionStatusLed="green:wlan5g"
        ;;
esac

setLedAttribute()
{
    [ -f "/sys/class/leds/$1/$2" ] && echo "$3" > "/sys/class/leds/$1/$2"
}

signalAutoprovisionWorking()
{
    setLedAttribute ${autoprovisionStatusLed} trigger none
    setLedAttribute ${autoprovisionStatusLed} trigger timer
    setLedAttribute ${autoprovisionStatusLed} delay_on 2000
    setLedAttribute ${autoprovisionStatusLed} delay_off 2000
}

signalAutoprovisionWaitingForUser()
{
    setLedAttribute ${autoprovisionStatusLed} trigger none
    setLedAttribute ${autoprovisionStatusLed} trigger timer
    setLedAttribute ${autoprovisionStatusLed} delay_on 200
    setLedAttribute ${autoprovisionStatusLed} delay_off 300
}

signalWaitingForPendrive()
{
    setLedAttribute ${autoprovisionUSBLed} trigger none
    setLedAttribute ${autoprovisionUSBLed} trigger timer
    setLedAttribute ${autoprovisionUSBLed} delay_on 200
    setLedAttribute ${autoprovisionUSBLed} delay_off 300
}

signalFormatting()
{
    setLedAttribute ${autoprovisionUSBLed} trigger none
    setLedAttribute ${autoprovisionUSBLed} trigger timer
    setLedAttribute ${autoprovisionUSBLed} delay_on 1000
    setLedAttribute ${autoprovisionUSBLed} delay_off 1000
}

stopSignallingAnything()
{
    # TODO this is wrong, they should be restored to their original state.
    # but then leds are only touched in the setup stage, which is ephemeral when things work as expected...
    setLedAttribute ${autoprovisionStatusLed} trigger none
    setLedAttribute ${autoprovisionUSBLed} trigger usbdev
}

setRootPassword()
{
    _password_=$1
    if [ "${_password_}" = "" ]; then
        # set and forget a random password merely to disable telnet. login will go through ssh keys.
        _password_=$(</dev/urandom sed 's/[^A-Za-z0-9+_]//g' | head -c 22)
    fi
    #echo "Setting root password to '"$password"'"
    log "Setting root password"
    printf  "$%\n$%\n" "${_password_}" "${_password_}" | passwd root
}
