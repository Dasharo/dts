#!/usr/bin/env bash

# set -Eeuo pipefail

##### Generic functions - could be useful also outside of DTS
#### Logging and colors
### Colors definitions
NORMAL='\033[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
# GRAY='\033[0;30m'
# FGRED='\033[0;41m'

VERBOSE="false"

# stdout console logs, which can be suppressed if QUEST is set to "true"
log() {
  local _msg="$1"

  if [ "${VERBOSE}" = "true" ]; then
    echo "$_msg"
  fi
}

### Color echo functions
function echo_green() {
  echo -e "$GREEN""$1""$COLOR_OFF"
}

function echo_red() {
  echo -e "$RED""$1""$COLOR_OFF"
}

function echo_yellow() {
  echo -e "$YELLOW""$1""$COLOR_OFF"
}

## Error handling
function error_exit() {
  local _error_msg="$1"
  echo_red "$_error_msg"
  exit 1
}

function error_check() {
  local _error_code=$?
  local _error_msg="$1"
  if [ "${_error_code}" -ne 0 ]; then
    error_exit "${_error_msg} (error code: ${_error_code})"
  fi
}

##### DTS-specific functions

###############################################################################
# Gathers information about the hardware, and firmware running on that
# hardware. This information is exported into global variables, so can be later
# used at different times during operation.
#
# Globals:
#   BOARD_VENDOR
#   SYSTEM_MODEL
#   BOARD_MODEL
#   BIOS_VENDOR
#   BIOS_VERSION
# Arguments:
#   None
# Outputs:
#   None
#
###############################################################################
function get_hw_info() {
  # Hardware information
  SYS_MANUF="$(dmidecode -s system-manufacturer)"
  SYS_PN="$(dmidecode -s system-product-name)"
  BOARD_PN="$(dmidecode -s baseboard-product-name)"

  # Firmware information
  BIOS_VENDOR="$(dmidecode -s bios-vendor)"
  BIOS_VERSION="$(dmidecode -s bios-version)"

  check_if_dasharo
}

###############################################################################
# Check whether Dasharo is already installed. Save the true/false result to a
# global variable. If Dasharo is installed, save the version to the
# DASHARO_VERSION global variable.
#
# Globals:
#   IS_DASHARO
#   DASHARO_VERSION
# Arguments:
#   None
# Outputs:
#   None
#
###############################################################################
function check_if_dasharo() {
  local _expected_dasharo_vendor="3mdeb"
  local _expected_dasharo_version="Dasharo"

  if [[ ${BIOS_VENDOR} == *${_expected_dasharo_vendor}* &&
        ${BIOS_VERSION} == *${_expected_dasharo_version}* ]]; then
    IS_DASHARO="true"
    DASHARO_VERSION="$(echo "$BIOS_VERSION" | cut -d ' ' -f 3 | tr -d 'v')"
  else
    IS_DASHARO="false"
  fi
}

###############################################################################
# Check whether Dasharo SE credentials are already provided. Save the
# true/false result to a global variable
#
# Globals:
#   IS_SE_LOGGED
# Arguments:
#   None
# Outputs:
#   None
#
###############################################################################
# function check_if_se_logged() {
#   # TODO: implement
#   IS_SE_LOGGED="false"
# }

function show_header() {
  local _os_version
  _os_version=$(grep "VERSION_ID" "${OS_VERSION_FILE}" | cut -d "=" -f 2-)
  printf "\ec"
  echo -e "${NORMAL}\n Dasharo Tools Suite Script ${_os_version} ${NORMAL}"
  echo -e "${NORMAL} (c) Dasharo <contact@dasharo.com> ${NORMAL}"
  echo -e "${NORMAL} Report issues at: https://github.com/Dasharo/dasharo-issues ${NORMAL}"
  echo -e "${BLUE}*********************************************************${NORMAL}"
  echo -e "${BLUE}**${NORMAL}                HARDWARE INFORMATION ${NORMAL}"
  echo -e "${BLUE}*********************************************************${NORMAL}"
  echo -e "${BLUE}**${YELLOW}    System Manufacturer: ${NORMAL}${SYS_MANUF}"
  echo -e "${BLUE}**${YELLOW}    System Product Name: ${NORMAL}${SYS_PN}"
  echo -e "${BLUE}**${YELLOW} Baseboard Product Name: ${NORMAL}${BOARD_PN}"
  echo -e "${BLUE}*********************************************************${NORMAL}"
  echo -e "${BLUE}**${NORMAL}                FIRMWARE INFORMATION ${NORMAL}"
  echo -e "${BLUE}*********************************************************${NORMAL}"
  echo -e "${BLUE}**${YELLOW}            BIOS Vendor: ${NORMAL}${BIOS_VENDOR}"
  echo -e "${BLUE}**${YELLOW}           BIOS Version: ${NORMAL}${BIOS_VERSION}"

  # check if update available
  # if [ "$wpEnabled" = true ]; then
  #     echo -e "${MENU}**${NUMBER}    Fw WP: ${RED_TEXT}Enabled${NORMAL}"
  # WP_TEXT=${RED_TEXT}
  # else
  #     echo -e "${MENU}**${NUMBER}    Fw WP: ${NORMAL}Disabled"
  # WP_TEXT=${GREEN_TEXT}
  # fi
  echo -e "${BLUE}*********************************************************${NORMAL}"
}

show_menu() {
  show_header

  # if [[ "$hasUEFIoption" = true ]]; then
  #     echo -e "${MENU}**${WP_TEXT} [WP]${NUMBER} 1)${MENU} Install/Update UEFI (Full ROM) Firmware ${NORMAL}"
  # else
  #     echo -e "${GRAY_TEXT}**     ${GRAY_TEXT} 1)${GRAY_TEXT} Install/Update UEFI (Full ROM) Firmware${NORMAL}"
  # fi
  # if [[ "$isChromeOS" = false  && "$isFullRom" = true ]]; then
  #     echo -e "${MENU}**${WP_TEXT} [WP]${NUMBER} 2)${MENU} Restore Stock Firmware ${NORMAL}"
  # else
  #     echo -e "${GRAY_TEXT}**     ${GRAY_TEXT} 2)${GRAY_TEXT} Restore Stock ChromeOS Firmware ${NORMAL}"
  # fi
  # if [[ "${device^^}" = "EVE" ]]; then
  #     echo -e "${MENU}**${WP_TEXT} [WP]${NUMBER} D)${MENU} Downgrade Touchpad Firmware ${NORMAL}"
  # fi
  # if [[ "$unlockMenu" = true || "$isUEFI" = true ]]; then
  #     echo -e "${MENU}**${WP_TEXT}     ${NUMBER} C)${MENU} Clear UEFI NVRAM ${NORMAL}"
  # fi
  echo -e "${BLUE}**${YELLOW}     1)${BLUE} Dasharo HCL report${NORMAL}"
  if [[ "$IS_DASHARO" == "true" ]]; then
    echo -e "${BLUE}**${YELLOW}     2)${BLUE} Update Dasharo Firmware${NORMAL}"
  else
    echo -e "${BLUE}**${YELLOW}     2)${BLUE} Install Dasharo Firmware${NORMAL}"
  fi
  echo -e "${BLUE}**${YELLOW}     3)${BLUE} Restore firmware from backup${NORMAL}"
  echo -e "${BLUE}*********************************************************${NORMAL}"
  echo -e "${YELLOW}Select a menu option or${NORMAL}"
  echo -ne "${RED}R${NORMAL} to reboot  ${NORMAL}"
  echo -ne "${RED}P${NORMAL} to poweroff  ${NORMAL}"
  echo -ne "${RED}S${NORMAL} to enter shell  ${NORMAL}"
  echo -e "${RED}K${NORMAL} to manage SE credentials${NORMAL}"

  read -er opt
  case $opt in
    1)
      dasharo_hcl_report
      ;;

    2)
      ;;

    [rR])
      echo -e "\nRebooting...\n";
      ${CMD_REBOOT}
      ;;

    [pP])
      echo -e "\nPowering off...\n";
      ${CMD_POWEROFF}
      ;;

    [sS])
      ${CMD_SHELL}
      ;;
    *)
      clear
      ;;
  esac
}

check_network_connection() {
  echo 'Waiting for network connection ...'
  n="5"
  while : ; do
    ping -c 3 cloud.3mdeb.com > /dev/null 2>&1 && break
    n=$((n-1))
    if [ "${n}" == "0" ]; then
      echo 'No network connection to 3mdeb cloud, please recheck Ethernet connection'
      return 1
    fi
    sleep 1
  done
  return 0
}
