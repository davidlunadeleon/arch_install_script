#!/usr/bin/bash

###############################################################################
# Install all necessary packages previous to doing arch-chroot
###############################################################################

# Essential packages per the installatiion guide
pacstrap /mnt base linux linux-firmware

# Other important packages
pacstrap /mnt grub btrfs-progs efibootmgr sudo base-devel git

# Sound
pacstrap /mnt pipewire pipewire-alsa pipewire-pulse

# Display
pacstrap /mnt wayland sway bemenu mako swaybg swayidle waybar swaylock \
	xorg-xwayland i3status

# User preference
pacstrap /mnt zsh vim firefox kitty rust python typescript go gcc neovim

if [ -n "$AIS_NETWORK_SSID" ]; then
	pacstrap /mnt iwd
fi
