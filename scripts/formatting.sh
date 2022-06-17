#!/usr/bin/bash

###############################################################################
# Format all partitions with the appropriate file system. In the case of btfs,
# create the file system merging the different drives and the partition 3 in
# main drive.
###############################################################################

echo Formatting /efi partition...
mkfs.fat -F32 ${AIS_MAIN_DRIVE}1
echo Done formatting /efi partition

echo Formatting swap partition...
mkswap /dev/mapper/swap
echo Done formatting swap partition

echo Formatting root partition...
IFS=';' read -ra ais_mapped_names <<< "$AIS_MAPPED_NAMES"
if (( ${#ais_mapped_names[@]} == 0)); then
	mkfs.btrfs -L root /dev/mapper/root
else
	for ((i = 0; i < ${#ais_mapped_names[@]}; ++i)); do
		ais_mapped_names[$i]="/dev/mapper/${ais_mapped_names[$i]}"
	done
	mkfs.btrfs -L root -d single -m raid1 /dev/mapper/root $ais_mapped_names
fi
echo Done formatting root partition
