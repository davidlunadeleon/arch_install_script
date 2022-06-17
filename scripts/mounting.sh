#!/usr/bin/bash

###############################################################################
# Mount all partitions and handle the creation of btrfs subvolumes
###############################################################################

echo Mounting partitions...

echo Creating subvolumes...

mount LABEL=root /mnt

# Subvolumes used for backups
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots

# Subvolumes excluded from backups
mkdir -p /mnt/var
btrfs subvolume create /mnt/var/cache
btrfs subvolume create /mnt/var/log
btrfs subvolume create /mnt/var/tmp

umount /mnt

echo Done creating subvolumes

# Mount previously created subvolumes
mount_subvolume() {
	echo Mounting $2
	mkdir -p $1
	mount -o compress=zstd,subvol=$2 /dev/mapper/root $1
}

echo Mounting subvolumes...

echo Mounting @
mount -o compress=zstd,subvol=@ /dev/mapper/root /mnt
mount_subvolume /mnt/home @home
mount_subvolume /mnt/.snapshots @snapshots
mount_subvolume /mnt/var/cache var/cache
mount_subvolume /mnt/var/log var/log
mount_subvolume /mnt/var/tmp var/tmp

echo Done mounting subvolumes

echo Mounting efi partition...

mkdir -p /mnt/efi
mount ${AIS_MAIN_DRIVE}1 /mnt/efi

echo Done mounting efi partition

echo Enabling swap...

swapon /dev/mapper/swap

echo Done enabling swap

echo Done mounting partitions
