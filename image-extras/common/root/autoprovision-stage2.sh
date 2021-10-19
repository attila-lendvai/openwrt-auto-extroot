#!/bin/sh

# autoprovision stage 2: this script will be executed upon boot if the extroot was successfully mounted (i.e. rc.local is run from the extroot overlay)

. /root/autoprovision-functions.sh

installPackages()
{
    signalAutoprovisionWaitingForUser

    until (opkg update)
     do
        log "opkg update failed. No internet connection? Retrying in 15 seconds..."
        sleep 15
    done

    signalAutoprovisionWorking

    log "Autoprovisioning stage2 is about to install packages"

    # switch ssh from dropbear to openssh (needed to install sshtunnel)
    #opkg remove dropbear
    #opkg install openssh-server openssh-sftp-server sshtunnel

    #/etc/init.d/sshd enable
    #mkdir /root/.ssh
    #chmod 0700 /root/.ssh
    #mv /etc/dropbear/authorized_keys /root/.ssh/
    #rm -rf /etc/dropbear

    # CUSTOMIZE
    # install some more packages that don't need any extra steps
    opkg install lua luci ppp-mod-pppoe screen mc zip unzip logrotate

    # this is needed for the vlans on tp-link 3020 with only a single hw ethernet port
    opkg install kmod-macvlan ip

    # just in case if we were run in a firmware that didn't already had luci
    /etc/init.d/uhttpd enable
}

autoprovisionStage2()
{
    log "Autoprovisioning stage2 speaking"

    # TODO this is a rather sloppy way to test whether stage2 has been done already, but this is a shell script...
    if [ $(uci get system.@system[0].log_type) == "file" ]; then
        log "Seems like autoprovisioning stage2 has been done already. Running stage3."
        #/root/autoprovision-stage3.py
    else
        signalAutoprovisionWorking

	echo Updating system time using ntp; otherwise the openwrt.org certificates are rejected as not yet valid.
        ntpd -d -q -n -p 0.openwrt.pool.ntp.org

        # CUSTOMIZE: with an empty argument it will set a random password and only ssh key based login will work.
        # please note that stage2 requires internet connection to install packages and you most probably want to log in
        # on the GUI to set up a WAN connection. but on the other hand you don't want to end up using a publically
        # available default password anywhere, therefore the random here...
        #setRootPassword ""

        installPackages

        crontab - <<EOF
# */10 * * * * /root/autoprovision-stage3.py
0 0 * * * /usr/sbin/logrotate /etc/logrotate.conf
EOF

        mkdir -p /var/log/archive

        # logrotate is complaining without this directory
        mkdir -p /var/lib

        uci set system.@system[0].log_type=file
        uci set system.@system[0].log_file=/var/log/syslog
        uci set system.@system[0].log_size=0

        uci commit
        sync
        reboot
    fi
}

autoprovisionStage2
