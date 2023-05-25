#!/usr/bin/env bash

export OS_VERSION_FILE="/etc/os-release"

# Path to log files
export DTS_ERR_LOG="/var/local/dts-err.log"
export FLASHROM_LOG_="/var/local/flashrom.log"

# Commands executed from the main DTS menu
export CMD_POWEROFF="/sbin/poweroff"
export CMD_REBOOT="/sbin/reboot"
export CMD_SHELL="/bin/bash"

# Dasharo Supporters Entrance variables
export SE_credential_file="/etc/cloud-pass"

# base values
export BASE_CLOUDSEND_LOGS_URL="39d4biH4SkXD8Zm"
export BASE_CLOUDSEND_PASSWORD="1{\[\k6G"

# base values
export CLOUDSEND_LOGS_URL="$BASE_CLOUDSEND_LOGS_URL"
export CLOUDSEND_PASSWORD="$BASE_CLOUDSEND_PASSWORD"
