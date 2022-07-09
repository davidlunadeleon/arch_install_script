# arch_install_script
Custom script to install ArchLinux

## WARNING!!!

This script will wipe all drives specified in the `envs.sh` file variables related to drives. Do a proper backup before running the script, since the drives will be securely wiped for encryption. All data will be lost and become unrecoverable!

## Description

Simple, minimal, and mostly hands-off ArchLinux install script with the following configuration:

- User:
	- Editor(s): vim & neovim
	- Shell: zsh
	- Terminal: kitty
	- Window Manager: i3-gaps

- System:
	- AUR helper: paru
	- Bootloader: GRUB
	- Display Manager and greeter: lightdm with lightdm-webkit2-greeter with litarvan theme
	- Display Server: X
	- Encryption: LUKS2 in all partitions except /efi
	- File system: Ext4 partition on LVM
	- Partition table: GPT

## Instructions

1. Boot the archiso, following the initial instructions in the wiki's [installation guide](https://wiki.archlinux.org/title/Installation_guide).
2. Connect to a network.
2. `pacman -Sy git`
3. `git clone https://github.com/davidlunadeleon/arch_install_script.git`
4. `cd arch_install_script/`
7. `chmod +x install.sh`
5. Set all variables at the beginning of `envs.sh`
7. `./install.sh`
