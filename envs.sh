#!/usr/bin/bash

# Configuration variables

# Drives
# Main drive where the efi is located. The rest will be a partition used as 
# an LVM physical volume.
export AIS_MAIN_DRIVE=/dev/nvme0n1
# Any other drives to setup, if any. String with semicolon separated elements.
export AIS_OTHER_DRIVES=""

# Swap configuration
export AIS_SWAP_SIZE=4G

# LUKS Encryption passphrases
export AIS_ROOT_KEY=default
export AIS_SWAP_KEY=default
# Additional passprhases, if any. Must match the size of OTHER_DRIVES. String
# with semicolon separated elements.
export AIS_OTHER_DRIVES_KEYS=""

# Wireless connection configuration, if any
export AIS_NETWORK_SSID=""
export AIS_NETWORK_PASSWORD=default
export AIS_STATION=wlan0

# System config
export AIS_HOSTNAME=default
# String with semicolon separated elements.
export AIS_LOCALE_GEN_LOCALES="en_US.UTF-8 UTF-8;es_MX.UTF-8 UTF-8"
export AIS_LOCALE=en_US.UTF-8
export AIS_TIMEZONE=America/Monterrey
export AIS_USERNAME=user
export AIS_ROOT_PASSWORD=default
export AIS_USER_PASSWORD=default
# Either amd or intel, or leave empty if none should be installed
export AIS_MICROCODE=
