#!/usr/bin/bash

###############################################################################
# Encrypt the different partitions created in the previous step. All partitions
# use LUKS2.
###############################################################################

encrypt_partition() {
	# $1 - partition
	# $2 - mounted partition name
	# $3 - disk's encryption password
	echo -n $3 > key_file.txt
	echo YES | cryptsetup luksFormat --key-file key_file.txt --type luks1 $1
	cryptsetup open --key-file key_file.txt $1 $2
	rm key_file.txt
}

echo Encrypting swap partition...
encrypt_partition ${AIS_MAIN_DRIVE}2 swap $AIS_SWAP_KEY
echo Done encrypting swap

echo Encrypting / partition...
encrypt_partition ${AIS_MAIN_DRIVE}3 root $AIS_ROOT_KEY
echo Done encrypting / partition

IFS=';' read -ra ais_other_drives <<< "$AIS_OTHER_DRIVES"
IFS=';' read -ra ais_other_drives_keys <<< "$AIS_OTHER_DRIVES_KEYS"
AIS_MAPPED_NAMES=""
# Partition and encrypt other drives
for ((i = 0; i < ${#ais_other_drives[@]}; ++i)); do
	drive=${ais_other_drives[$i]}
	mapped_name=drive${i}
	echo Encrypting $drive
	encrypt_partition ${drive}1 $mapped_name ${ais_other_drives_keys[$i]}
	AIS_MAPPED_NAMES="${mapped_name};${AIS_MAPPED_NAMES}"
	echo Done encrypting ${drive}
done
# Remove trailing semicolon from drives' list and export the array
if [ -n "$AIS_MAPPED_NAMES" ]; then
	AIS_MAPPED_NAMES=$(echo $AIS_MAPPED_NAMES | sed 's/.$//')
fi
export AIS_MAPPED_NAMES
