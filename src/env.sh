#!/usr/bin/env bash

OS_VERSION_FILE="/etc/os-release"

# Path to log files
DTS_ERR_LOG="/var/local/dts-err.log"
FLASHROM_LOG_="/var/local/flashrom.log"

# Commands executed from the main DTS menu
CMD_POWEROFF="/sbin/poweroff"
CMD_REBOOT="/sbin/reboot"
CMD_SHELL="/bin/bash"
CMD_DASHARO_HCL_REPORT="/usr/sbin/dasharo-hcl-report"
CMD_NCMENU="/usr/sbin/novacustom_menu"
CMD_DASHARO_DEPLOY="/usr/sbin/dasharo-deploy"
CMD_CLOUD_LIST="/usr/sbin/cloud_list"
CMD_EC_TRANSITION="/usr/sbin/ec_transition"

# Dasharo Supporters Entrance variables
SE_credential_file="/etc/cloud-pass"
Cloud_base_url="https://cloud.3mdeb.com/index.php/s/"
# base values
BASE_CLOUDSEND_LOGS_URL="39d4biH4SkXD8Zm"
BASE_CLOUDSEND_PASSWORD="1{\[\k6G"
# base values
export CLOUDSEND_LOGS_URL="$BASE_CLOUDSEND_LOGS_URL"
export CLOUDSEND_PASSWORD="$BASE_CLOUDSEND_PASSWORD"

