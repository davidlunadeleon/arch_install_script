#!/usr/bin/bash

###############################################################################
# Install all necessary packages previous to doing arch-chroot
###############################################################################

echo "
############################################################
#
# Installing essential packages using pacstrap. Installing
# the following packages and package groups:
#	- base
#	- linux
#	- linux-firmware
#	- lvm2
#	- grub
#	- efibootmgr
#	- sudo
#	- base-devel
#
############################################################
"

# Essential packages per the installatiion guide
pacstrap /mnt base linux linux-firmware

# Other important packages
pacstrap /mnt lvm2 grub efibootmgr sudo base-devel

echo "
############################################################
#
# Done installing essential packages
#
############################################################
"
