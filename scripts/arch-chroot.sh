#!/usr/bin/bash

###############################################################################
# Perform all necessary operations as root in the installed system
###############################################################################

source /root/scripts/envs.sh

# Handle system clock and timezone
ln -sf /usr/share/zoneinfo/${AIS_TIMEZONE} /etc/localtime
hwclock --systohc

# Handle locales
IFS=';' read -ra ais_locale_gen_locales <<< "$AIS_LOCALE_GEN_LOCALES"
for locale in "${ais_locale_gen_locales[@]}"; do
	sed -i "s/#${locale}/${locale}/" /etc/locale.gen
done
locale-gen
echo "LANG=${AIS_LOCALE}" > /etc/locale.conf
echo $AIS_HOSTNAME > /etc/hostname

# Add keyfile to the / partition
dd bs=512 count=4 if=/dev/random of=/etc/root_keyfile.bin iflag=fullblock
chmod 600 /etc/root_keyfile.bin
echo -n ${AIS_ROOT_KEY} | \
	cryptsetup luksAddKey ${AIS_MAIN_DRIVE}3 /etc/root_keyfile.bin

IFS=';' read -ra ais_other_drives <<< "$AIS_OTHER_DRIVES"
IFS=';' read -ra ais_other_drives_keys <<< "$AIS_OTHER_DRIVES_KEYS"
for ((i = 0; i < ${#ais_other_drives[@]}; ++i)); do
	echo -n ${ais_other_drives_keys[$i]} | \
		cryptsetup luksAddKey ${ais_other_drives[$i]}1 /etc/root_keyfile.bin
done

# Add keyfile to the swap partition
dd bs=512 count=4 if=/dev/random of=/etc/swap_keyfile.bin iflag=fullblock
chmod 600 /etc/swap_keyfile.bin
echo -n ${AIS_SWAP_KEY} | \
	cryptsetup luksAddKey ${AIS_MAIN_DRIVE}2 /etc/swap_keyfile.bin

# Auto open swap
if [[ $AIS_MAIN_DRIVE =~ /dev/nvme.* ]]; then
	ALLOW_DISCARDS="--allow-discards"
else
	ALLOW_DISCARDS=""
fi
cat<<EOF > /etc/initcpio/hooks/openswap
run_hook ()
{
	x=0;
	while [ ! -b /dev/mapper/root ] && [ \$x - le 10 ]; do
		x=\$((x+1))
		sleep .2
	done
	mkdir key_device
	mount /dev/mapper/root key_device
	cryptsetup open --key-file key_device/etc/swap_keyfile.bin ${ALLOW_DISCARDS} ${AIS_MAIN_DRIVE}2 swap
	umount key_device
}
EOF

cat<<EOF > /etc/initcpio/install/openswap
build ()
{
	add_runscript
}
help ()
{
cat<<HELPEOF
	This opens the swap encrypted partition /dev/${AIS_MAIN_DRIVE}2 in /dev/mapper/swap
HELPEOF
}
EOF

# Add swap to fstab
LINE=$(grep -n "none.*swap" /etc/fstab | awk -F ":" '{printf $1}')
sed -i "${LINE} s/.*/\/dev\/mapper\/swap swap swap defaults 0 0/" /etc/fstab

# Password and user account
echo Set root password:
passwd
useradd -m -s /usr/bin/zsh ${AIS_USERNAME}
echo Set $AIS_USERNAME password:
passwd ${AIS_USERNAME}

LINE=$(grep -n "root ALL(ALL) ALL" /etc/sudoers | awk -F ":" '{printf $1}')
sed -i "$((LINE + 1))i ${AIS_USERNAME} ALL=(ALL) ALL" /etc/sudoers

# Install the AUR helper paru
echo Installing paru...

su ${AIS_USERNAME} <<EOSU
	cd ~
	git clone https://aur.archlinux.org/paru-bin.git
	cd paru-bin
	makepkg -si --noconfirm
	cd ~ && rm -rf paru-bin/
EOSU

echo Done installing paru
echo "Installing greetd..."

if [ "$AIS_MICROCODE" == "amd" ]; then
	microcode_package='amd-ucode'
elif [ "$AIS_MICROCODE" == "intel" ]; then
	microcode_package='intel-ucode'
else
	microcode_package=""
fi

sudo -u ${AIS_USERNAME} paru --noconfirm -S greetd greetd-gtkgreet

echo Done installing extra packages

mkdir -p /etc/greetd
echo sway >> /etc/greetd/environments


# Services
echo Enabling services...

systemctl enable greetd.service
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable systemd-timesyncd.service
if [ -n "$AIS_NETWORK_SSID" ]; then
	systemctl enable iwd.service
fi

echo Done enabling services

timedatectl set-ntp true

# Network configuration
cat<<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.0.1	${AIS_HOSTNAME}
EOF

# mkinitcpio.conf
echo Editing mkinitcpio.conf...

sed -i "s/^BINARIES=()/BINARIEs=(btrfs)/" /etc/mkinitcpio.conf
sed -i "s/^HOOKS=(.*)/HOOKS=(base systemd btrfs autodetect keyboard sd-vconsole\
 consolefont modconf block sd-encrypt openswap resume filesystems fsck)/"\
 /etc/mkinitcpio.conf

echo Done editing mkinitcpio.conf

# GRUB configuration
echo Setting up GRUB...

get_partition_uuid() {
	uuid=$(blkid $1 | grep -oE " UUID=\"[-[:alnum:]]*\"" | sed 's/UUID=//' | sed 's/"//g')
	echo $uuid
}

echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
echo "root UUID=$(get_partition_uuid ${AIS_MAIN_DRIVE}3) none timeout=10" >> /etc/crypttab.initramfs
for ((i = 0; i < ${#ais_other_drives[@]}; ++i)); do
	echo "drive${i} UUID=$(\
		get_partition_uuid ${ais_other_drives[$i]}1\
	) none timeout=10" >> /etc/crypttab.initramfs
done
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3\
 quiet splash rootflags=subvol=/@ \
 root=/dev/mapper/root resume=/dev/mapper/swap\"|" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

mkinitcpio -P

echo Done configuring GRUB

rm -rf /root/scripts

# Exit the arch-chroot environment
exit
