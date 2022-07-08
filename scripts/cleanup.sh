#!/usr/bin/bash

###############################################################################
# Perform any cleanup tasks, such as unmounting and closing partitions
###############################################################################

echo Unmounting partitions...

umount -R /mnt
swapoff /dev/mapper/main-swap

echo Done unmounting partitions

echo Closing encrypted partitions...

cryptsetup close main-home
cryptsetup close main-root
cryptsetup close main-swap
cryptsetup close crypto-boot
cryptsetup close crypto-system0
IFS=';' read -ra ais_mapped_names <<< "$AIS_MAPPED_NAMES"
for name in "${ais_mapped_names[@]}"; do
	cryptsetup close $name
done

echo Done closing encrypted partitions
