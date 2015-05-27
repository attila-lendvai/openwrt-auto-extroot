# What

It's a script to build a customized OpenWRT firmware that will
automatically set up
[extroot](http://wiki.openwrt.org/doc/howto/extroot) on any (!)
storage device plugged into the USB port (`/dev/sda`).

# Why

So that e.g. customers can buy a router on their own, flash our
firmware, plug in a pendrive, and manage their SIP (telephony) node
from our webapp.

# Status

This is more of a template than something standalone. You most
probably want to customize this script here and there; search for
`CUSTOMIZE` for places of interest.

I've extracted this from a project where OpenWRT nodes auto-provision
themselves in 3 stages, but I thought it's useful enough for making it
public (stage 1: extroot setup; stage 2: install packages; stage 3: a
Python script for app-level sync).

At the time of writing it only supports a few `ar71xx` routers but
it's easy to extend it.

## Tested with

[OpenWRT Chaos Calmer 15.05 RC1](https://downloads.openwrt.org/chaos_calmer/15.05-rc1/)
on a TP-Link WDR4300.

# Building

e.g. `./build.sh TLWDR4300`

Results will be under `build/OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64`.

To see a list of available targets, run this in the ImageBuilder dir: ```make info```.

# Usage

After flashing the firmware the router will have the standard
`192.168.1.1` IP address, and SSH will listen there using the keys
specified in `image-extras/etc/dropbear/authorized_keys`.

Once connected, you can read the log with `logread -f`.

The autoprovision script will wait for any `/dev/sda` to show up, then
erase it and set up a `swap`, an `extroot`, and a `data` filesystem,
and then reboots.

In stage 2 it will need an internet connection, so you should connect
to its [LuCI interface](http://192.168.1.1) to set up an Internet
upstream, and then it will automatically continue installing packages,
finishing the whole process, and then do a final reboot.
