#!/usr/bin/bash

###############################################################################
# Mount all partitions and handle the creation of btrfs subvolumes
###############################################################################

echo "
############################################################
#
# Mounting partitions and starting swap...
#
############################################################
"

mount /dev/mapper/main-root /mnt

mkdir /mnt/home
mount /dev/mapper/main-home /mnt/home

mkdir /mnt/boot
mount /dev/mapper/crypto-boot /mnt/boot

mkdir /mnt/efi
mount ${AIS_MAIN_DRIVE}1 /mnt/efi

swapon /dev/mapper/main-swap

echo "
############################################################
#
# Done mounting partitions
#
############################################################
"
