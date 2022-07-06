#!/usr/bin/bash

###############################################################################
# Encrypt the different partitions created in the previous step. All partitions
# use LUKS2, except the efi partition.
###############################################################################

encrypt_partition() {
	# $1 - partition
	# $2 - mounted partition name
	# $3 - disk's encryption password
	# $4 - luks1 or luks2 luks format type
	echo -n $3 > key_file.txt
	echo YES | cryptsetup open --type plain -d /dev/urandom $1 to_be_wiped
	dd if=/dev/zero of=/dev/mapper/to_be_wiped status=progress
	cryptsetup close to_be_wiped
	echo YES | cryptsetup luksFormat \
		--key-file key_file.txt \
		--type $4 \
		--key-size 512 \
		--hash sha512 \
		--iter-time 5000 \
		--use-random \
		$1
	cryptsetup open --key-file key_file.txt $1 $2
	rm key_file.txt
}

echo "
############################################################
#
# Encrypting boot partition...
#
############################################################
"

encrypt_partition ${AIS_MAIN_DRIVE}2 crypto-boot $AIS_BOOT_KEY luks1

echo "
############################################################
#
# Done encrypting boot partition
#
############################################################
"

echo "
############################################################
#
# Encrypting system0 partition...
#
############################################################
"

encrypt_partition ${AIS_MAIN_DRIVE}3 crypto-system0 $AIS_SYSTEM0_KEY luks2

echo "
############################################################
#
# Done encrypting root partition
#
############################################################
"

IFS=';' read -ra ais_other_drives <<< "$AIS_OTHER_DRIVES"
IFS=';' read -ra ais_other_drives_keys <<< "$AIS_OTHER_DRIVES_KEYS"
AIS_MAPPED_NAMES=""
# Partition and encrypt other drives
for ((i = 0; i < ${#ais_other_drives[@]}; ++i)); do
	drive=${ais_other_drives[$i]}
	mapped_name=crypto-system$((i+1))

	echo "
	############################################################
	#
	# Encrypting $drive, with a single partition named
	# $mapped_name...
	#
	############################################################
	"

	encrypt_partition ${drive}1 $mapped_name ${ais_other_drives_keys[$i]} luks2
	AIS_MAPPED_NAMES="${mapped_name};${AIS_MAPPED_NAMES}"

	echo "
	############################################################
	#
	# Done encrypting ${drive}
	#
	############################################################
	"
done
export AIS_MAPPED_NAMES
