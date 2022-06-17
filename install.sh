#!/usr/bin/bash

# Prepare space for logs
mkdir logs/
touch logs/arch_install_script.log

message="ArchLinux install script..."
echo $message
echo $message >> logs/arch_install_script.log


chmod +x envs.sh
chmod +x scripts/partitions.sh
chmod +x scripts/encryption.sh
chmod +x scripts/formatting.sh
chmod +x scripts/mounting.sh
chmod +x scripts/pacstrap.sh
chmod +x scripts/arch-chroot.sh
chmod +x scripts/cleanup.sh

# Load variables
source envs.sh

# Miscellaneous instruction
timedatectl set-ntp true

# Run scripts
source scripts/partitions.sh > >(tee -a logs/arch_install_script.log)
source scripts/encryption.sh > >(tee -a logs/arch_install_script.log)
source scripts/formatting.sh > >(tee -a logs/arch_install_script.log)
source scripts/mounting.sh > >(tee -a logs/arch_install_script.log)
source scripts/pacstrap.sh > >(tee -a logs/arch_install_script.log)

# Miscellaneous instructions
genfstab -U /mnt >> /mnt/etc/fstab
mkdir -p /mnt/root/scripts/
cp envs.sh /mnt/root/scripts/envs.sh
cp scripts/arch-chroot.sh /mnt/root/scripts/arch-chroot.sh


arch-chroot /mnt /root/scripts/arch-chroot.sh > >(tee -a logs/arch_install_script.log)
source scripts/cleanup.sh > >(tee -a logs/arch_install_script.log)

message="Done installing ArchLinux. Goodbye!"
echo $message
echo $message >> logs/arch_install_script.log
