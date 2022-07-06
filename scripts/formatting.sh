#!/usr/bin/bash

###############################################################################
# Format all partitions with the appropriate file system.
###############################################################################

echo "
############################################################
#
# Formatting /efi partition...
#
############################################################
"

mkfs.fat -F32 ${AIS_MAIN_DRIVE}1

echo "
############################################################
#
# Done formatting /efi partition
#
############################################################
"

echo "
############################################################
#
# Formatting boot partition...
#
############################################################
"

mkfs.ext2 /dev/mapper/crypto-boot

echo "
############################################################
#
# Done formatting boot partition
#
############################################################
"

echo "
############################################################
#
# Init LVM physical volumes and create main volume group...
#
############################################################
"

P_VOLUMES="/dev/mapper/crypto-system0"
pvcreate $P_VOLUMES
IFS=';' read -ra ais_mapped_names <<< "$AIS_MAPPED_NAMES"
for ((i = 0; i < ${#ais_mapped_names[@]}; ++i)); do
	VOL_NAME="/dev/mapper/${ais_mapped_names[$i]}"
	pvcreate $VOL_NAME
	P_VOLUMES="$P_VOLUMES $VOL_NAME"
done
vgcreate main $P_VOLUMES

echo "
############################################################
#
# Done initializing LVM PVs and creating main VG
#
############################################################
"

echo "
############################################################
#
# Creating LVM logical volumes...
#
############################################################
"

lvcreate -L $AIS_SWAP_SIZE main -n swap
lvcreate -L $AIS_ROOT_SIZE main -n root
lvcreate -l 100%FREE main -n home

echo "
############################################################
#
# Done creating the logical subvolumes swap, root, and home
#
############################################################
"

echo "
############################################################
#
# Formatting logical volumes...
#
############################################################
"

mkfs.ext4 /dev/mapper/main-root
mkfs.ext4 /dev/mapper/main-home
mkswap /dev/mapper/main-swap

echo "
############################################################
#
# Done formatting logical volumes...
#
############################################################
"
