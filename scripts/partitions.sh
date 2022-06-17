#!/usr/bin/bash

###############################################################################
# Partition the main drive and the other drives if they exist. The main drive
# ends up having the /efi partition, swap partition and everything else is
# dedicated to the root partition that uses btrfs.
###############################################################################

echo Partitioning drives...
echo Partitioning ${AIS_MAIN_DRIVE}...
fdisk $AIS_MAIN_DRIVE <<EOF
g
n


+512M
t
uefi
n


+${AIS_SWAP_SIZE}
t
2
linux
n



t
3
linux
w
EOF
echo Done partitioning ${AIS_MAIN_DRIVE}

IFS=';' read -ra ais_other_drives <<< "$AIS_OTHER_DRIVES"
for ((i = 0; i < ${#ais_other_drives[@]}; ++i)); do
	drive=${ais_other_drives[$i]}
	echo Partitioning ${drive}
	fdisk $drive <<EOF
	g
	n



	t
	linux
	w
EOF
	echo Done partitioning ${drive}
done
