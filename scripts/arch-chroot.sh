#!/usr/bin/bash

###############################################################################
# Perform all necessary operations as root in the installed system
###############################################################################

source /root/scripts/envs.sh

pattern="nvme0n.*"
if [[ $AIS_MAIN_DRIVE =~ $pattern ]]; then
	export AIS_MAIN_DRIVE="${AIS_MAIN_DRIVE}p"
fi

# Sound
echo "
############################################################
#
# Enabling multilib...
#
############################################################
"

LINE=$(grep -n "#\[multilib\]" /etc/pacman.conf | awk -F ":" '{printf $1}')
sed -i "${LINE} s/#//" /etc/pacman.conf
sed -i "$((LINE+1)) s/#//" /etc/pacman.conf
pacman -Syu --noconfirm

echo "
############################################################
#
# Done enabling multilib
#
############################################################
"

# Sound
echo "
############################################################
#
# Installing pipewire and related packages...
#
############################################################
"

pacman -Sy --noconfirm pipewire pipewire-alsa pipewire-pulse pavucontrol easyeffects

echo "
############################################################
#
# Done installing pipewire and related packages
#
############################################################
"

# Display and window manager
echo "
############################################################
#
# Installing xorg, i3, and more display utilities...
#
############################################################
"

pacman -Sy --noconfirm xorg i3 dmenu rofi polybar arandr feh \
	lightdm lightdm-webkit2-greeter lightdm-webkit-theme-litarvan \
	tmux
sed -i "s/#greeter-session=.*/greeter-session=lightdm-webkit2-greeter/" /etc/lightdm/lightdm.conf
sed -i "s/webkit_theme.*=.*/webkit_theme	= litarvan/" /etc/lightdm/lightdm-webkit2-greeter.conf

echo "
############################################################
#
# Done installing xorg, i3, and utils
#
############################################################
"

# Drivers
echo "
############################################################
#
# Installing drivers...
#
############################################################
"

case $AIS_MICROCODE in
	amd)
		microcode_package="amd-ucode"
		;;
	intel)
		microcode_package="intel-ucode"
		;;
	*)
		microcode_package=""
		;;
esac

case $AIS_GRAPHICS_DRIVERS in
	intel)
		graphics_package="xf86-video-intel mesa lib32-mesa"
		;;
	amd)
		graphics_package="xf86-video-amdgpu mesa lib32-mesa"
		;;
	nvidia)
		graphics_package="nvidia nvidia-utils lib32-nvidia-utils"
		;;
	nouveau)
		graphics_package="xf86-video-nouveau mesa lib32-mesa"
		;;
	*)
		graphics_package=""
		;;
esac

pacman -Sy --noconfirm $microcode_package $graphics_package xorg-drivers

echo "
############################################################
#
# Done installing drivers
#
############################################################
"

# User preference
echo "
############################################################
#
# Installing other packages:
#	- git
#	- zsh
#	- vim
#	- neovim
#	- firefox
#	- kitty
#	- ranger
#	- chezmoi
#	- openssh
#	- playerctl
#
############################################################
"

PACKAGES="git zsh vim firefox kitty neovim ranger chezmoi \
	openssh playerctl htop thunar thunar-archive-plugin \
	thunar-media-tags-plugin thunar-volman skanlite cups cups-pdf mpv"

if [ -n "$AIS_NETWORK_SSID" ]; then
	PACKAGES="$PACKAGES iwd"
	cat<<EOF > /etc/systemd/network/25-wired.network
	[Match]
	Name=wlan0

	[Network]
	DHCP=yes
EOF
else
	cat<<EOF > /etc/systemd/network/20-wired.network
	[Match]
	Name=enp1s0

	[Network]
	DHCP=yes
EOF
fi

pacman -Sy --noconfirm  $PACKAGES

echo "
############################################################
#
# Done installing extra packages
#
############################################################
"

# Handle system clock and timezone
echo "
############################################################
#
# Handling system clock and timezone...
#
############################################################
"

ln -sf /usr/share/zoneinfo/${AIS_TIMEZONE} /etc/localtime
hwclock --systohc

echo "
############################################################
#
# Done handling system clock and timezone
#
############################################################
"

# Handle locales
echo "
############################################################
#
# Handling locales...
#
############################################################
"

IFS=';' read -ra ais_locale_gen_locales <<< "$AIS_LOCALE_GEN_LOCALES"
for locale in "${ais_locale_gen_locales[@]}"; do
	sed -i "s/#${locale}/${locale}/" /etc/locale.gen
done
locale-gen
echo "LANG=${AIS_LOCALE}" > /etc/locale.conf
echo $AIS_HOSTNAME > /etc/hostname

echo "
############################################################
#
# Done handling locales
#
############################################################
"

# Add keyfile to the all partitions
echo "
############################################################
#
# Adding keys to all encrypted partitions...
#
############################################################
"

KEYFILES=""

mkdir /etc/cryptsetup-keys.d
add_partition_key() {
	# $1 - key name
	# $2 - drive to add the key to
	# $3 - plain text partition's encryption password
	dd bs=512 count=8 if=/dev/random of=/etc/cryptsetup-keys.d/${1}.key iflag=fullblock
	chmod 0000 /etc/cryptsetup-keys.d/${1}.key
	echo -n $3 | \
		cryptsetup luksAddKey $2 /etc/${1}.key
	echo /etc/cryptsetup-keys.d/${1}.key
}

KEYFILES="$KEYFILES $(add_partition_key crypto-boot ${AIS_MAIN_DRIVE}2 $AIS_BOOT_KEY)"
KEYFILES="$KEYFILES $(add_partition_key crypto-system0 ${AIS_MAIN_DRIVE}3 $AIS_SYSTEM_KEY)"

IFS=';' read -ra ais_other_drives <<< "$AIS_OTHER_DRIVES"
IFS=';' read -ra ais_other_drives_keys <<< "$AIS_OTHER_DRIVES_KEYS"
for ((i = 0; i < ${#ais_other_drives[@]}; ++i)); do
	KEYFILES="$KEYFILES $(\
		add_partition_key crypto-system$((i+1)) ${ais_other_drives[$i]}1 \
		${ais_other_drives_keys[$i]}
	)"
done

echo "
############################################################
#
# Done adding encryption keys
#
############################################################
"

# Password and user account
echo "
############################################################
#
# Setting up passwords and user account...
#
############################################################
"

echo Set root password:
passwd
useradd -m -s /usr/bin/zsh ${AIS_USERNAME}
echo Set $AIS_USERNAME password:
passwd ${AIS_USERNAME}

LINE=$(grep -n "root ALL(ALL:ALL) ALL" /etc/sudoers | awk -F ":" '{printf $1}')
sed -i "$((LINE + 1))i ${AIS_USERNAME} ALL=(ALL:ALL) ALL" /etc/sudoers

echo "
############################################################
#
# Done setting up passwords and user account
#
############################################################
"

# Install the AUR helper paru
echo "
############################################################
#
# Installing paru...
#
############################################################
"

su ${AIS_USERNAME} <<EOSU
	cd ~
	git clone https://aur.archlinux.org/paru-bin.git
	cd paru-bin
	makepkg -si --noconfirm
	cd ~ && rm -rf paru-bin/
EOSU

echo "
############################################################
#
# Done installing paru
#
############################################################
"

# Dotfiles
echo "
############################################################
#
# Setting up dotfiles and neovim config, and installing AUR
# packages...
#
############################################################
"

su $AIS_USERNAME <<EOSU
	cd ~
	curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | gpg --import -
	chezmoi init --apply $AIS_DOTFILES_REPO
	git clone $AIS_NEOVIM_REPO .config/nvim
EOSU

su $AIS_USERNAME <<EOSU
	cd ~
	mkdir .ssh
	touch .ssh/environment-${AIS_HOSTNAME}
	echo "~/.fehbg &" >> .xinitrc
	echo "/home/${AIS_USERNAME}/.screenlayout/default.sh" >> .xprofile
EOSU

# Neovim
sudo -u $AIS_USERNAME paru -S --noconfirm nvim-packer-git

# Zsh
sudo -u $AIS_USERNAME paru -S --noconfirm oh-my-zsh-git

# Music
sudo -u $AIS_USERNAME paru -S --noconfirm spotify zscroll-git dbus-python

# i3 and rofi
sudo -u $AIS_USERNAME paru -S --noconfirm rofimoji

# Environments
sudo -u $AIS_USERNAME paru -S --noconfirm nvm
	
# Fonts
sudo -u $AIS_USERNAME paru -S --noconfirm adobe-source-han-sans-otc-fonts adobe-source-serif-otc-fonts ttf-cascadia-code nerd-fonts-complete noto-fonts-emoji

# Themes
sudo -u $AIS_USERNAME paru -S --noconfirm gtk3 gnome-themes-extra adwaita-qt5 adwaita-qt6 qt5ct lxappearance-gtk3 nordic-darker-theme nordic-theme papirus-folders-nordic kvantum kvantum-theme-nordic-git

echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment


echo "
############################################################
#
# Done setting up dotfiles and neovim config
#
############################################################
"

# Services
echo "
############################################################
#
# Enabling services...
#
############################################################
"

systemctl enable lightdm.service
systemctl enable cups.service
systemctl enable sshd.service
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable systemd-timesyncd.service
if [ -n "$AIS_NETWORK_SSID" ]; then
	systemctl enable iwd.service
fi

echo "
############################################################
#
# Done enabling services
#
############################################################
"

timedatectl set-ntp true

# Network configuration
echo "
############################################################
#
# Configuring hosts...
#
############################################################
"

cat<<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.0.1	${AIS_HOSTNAME}
EOF

echo "
############################################################
#
# Done configuring hosts
#
############################################################
"

# mkinitcpio.conf
echo "
############################################################
#
# Editing mkinitcpio.conf and related...
#
############################################################
"

cat<<EOF > /etc/vconsole.conf
KEYMAP=us
FONT=Lat2-Terminus16
EOF

sed -i "s|^FILES=()|FILES=($KEYFILES)|" /etc/mkinitcpio.conf
sed -i "s/^HOOKS=(.*)/HOOKS=(base systemd keyboard sd-vconsole autodetect \
 modconf block sd-encrypt lvm2 resume filesystems fsck)/" \
 /etc/mkinitcpio.conf

mkinitcpio -P
chmod 600 /boot/initramfs-linux*

cat<<EOF > /etc/pacman.d/hooks/99-initramfs-chmod.hook 
[Trigger]
Type = File
Operation = Install
Operation = Upgrade
Target = boot/vmlinuz-linux
Target = usr/lib/initcpio/*

[Action]
Description = Set proper permissions for linux initcpios...
When = PostTransaction
Exec = /usr/bin/chmod 600 /boot/initramfs-linux.img /boot/initramfs-linux-fallback.img
EOF

echo "
############################################################
#
# Done editing mkinitcpio.conf and related
#
############################################################
"

# GRUB configuration
echo "
############################################################
#
# Setting up GRUB...
#
############################################################
"

echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
LUKS_NAMES=""
DRIVE_UUID=$(blkid -o value -s UUID ${AIS_MAIN_DRIVE}2)
LUKS_NAMES="$LUKS_NAMES \
	rd.luks.name=${DRIVE_UUID}=crypto-boot"
DRIVE_UUID=$(blkid -o value -s UUID ${AIS_MAIN_DRIVE}3)
LUKS_NAMES="$LUKS_NAMES \
	rd.luks.name=${DRIVE_UUID}=crypto-system0"
for ((i = 0; i < ${#ais_other_drives[@]}; ++i)); do
	DRIVE_UUID=$(blkid -o value -s UUID ${ais_other_drives[$i]}1)
	LUKS_NAMES="$LUKS_NAMES rd.luks.name=${DRIVE_UUID}=crypto-system$((i+1))"
done
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|\
	GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 \
	quiet splash $LUKS_NAMES root=/dev/mapper/main-root \
	resume=/dev/mapper/main-swap\"|" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "
############################################################
#
# Done setting up GRUB
#
############################################################
"

mkinitcpio -P

rm -rf /root/scripts

# Exit the arch-chroot environment
exit
