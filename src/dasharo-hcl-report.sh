#!/usr/bin/env bash

REPORT_DIR="/tmp/dasharo-hcl-report"
PROGRESS_COUNTER=0
SUMMARY_FILE="${REPORT_DIR}/summary.txt"
ROM_FILE="${REPORT_DIR}/rom.bin"
FULL_UPLOAD_URL="https://cloud.3mdeb.com/index.php/s/"${CLOUDSEND_LOGS_URL}
CMD_DASHARO_DEPLOY="/usr/sbin/dasharo-deploy"

update_summary() {
  local _update_name="$1"
  local _log_file="$2"
  local _err_file="$3"
  local _set_unknown_status="$4"

  # Skip all automatic checks and set status to UNKNOWN if requested, or if the
  # log file does not exist
  if [[ "${_set_unknown_status}" = "true" -o ! -e ${_log_file} ]]; then
    echo -e [${YELLOW}"UNKNOWN"${NORMAL}]\t${_update_name} >> ${SUMMARY_FILE}
  return fi

  local _log_file_wc=$(wc -l "${_log_file}" 2> /dev/null | cut -d ' ' -f 1)
  local _err_file_wc=$(wc -l "${_err_file}" 2> /dev/null | cut -d ' ' -f 1)

  # Specific check for firmware dump - we check whether the firmware dump was
  # created
  if [ "${_log_file}" == "${REPORT_DIR}/flashrom.log" ]; then
    if [ "${_log_file_wc}" -ne 0 ] && [ -f "${ROM_FILE}" ]; then
      echo -e [${GREEN}"OK"${NORMAL}]"\t\t"${_update_name} >> ${SUMMARY_FILE}
    else
      echo -e [${RED}"ERROR"${NORMAL}]"\t\t"${_update_name} >> ${SUMMARY_FILE}
    fi
    return
  fi

  # Generic checks - we check whether useful logs and error messages were
  # produced
  if [ ${_log_file_wc} -ne 0 ] && [ "${_err_file_wc}" -eq 0 ]; then
    echo -e [${GREEN}"OK"${NORMAL}]"\t\t"${_update_name} >> ${SUMMARY_FILE}
  elif [ ${_log_file_wc} -eq 0 ] && [ "${_err_file_wc}" -ne 0 ]; then
    echo -e [${RED}"ERROR"${NORMAL}]"\t\t"${_update_name} >> ${SUMMARY_FILE}
  else
    echo -e [${YELLOW}"UNKNOWN"${NORMAL}]"\t"${_update_name} >> ${SUMMARY_FILE}
  fi
}

update_progress_bar() {
  PROGRESS_COUNTER=$((${PROGRESS_COUNTER} + 1))
  printf '#%.0s' $(seq 1 $PROGRESS_COUNTER)
}

execute_command() {
  local _command="$1"
  local _log_prefix="$2"
  local _update_name="$3"

  local _log_file="${REPORT_DIR}/${_log_prefix}.log"
  local _err_file="${REPORT_DIR}/${_log_prefix}.err.log"

  log "Dumping ${_update_name} ..."
  eval "${_command}" >> "${_log_file}" 2>> "${_err_file}"
  update_summary "${_update_name}" "${_log_file}" "${_err_file}" "false"
  update_progress_bar
}


print_hcl_disclaimer() {
  echo -e \
"Please note that the report is not anonymous, but we will use it only for\r
backup and future improvement of the Dasharo product. Every log is encrypted\r
and sent over HTTPS, so security is assured.\r
If you still have doubts, you can skip HCL report generation.\r\n
What is inside the HCL report? We gather information about:\r
  - PCI, Super I/O, GPIO, EC, audio, and Intel configuration,\r
  - MSRs, CMOS NVRAM, CPU info, DIMMs, state of touchpad, SMBIOS and ACPI tables,\r
  - Decoded BIOS information, full firmware image backup, kernel dmesg,\r
  - IO ports, input bus types, and topology - including I2C and USB,\r
\r
You can find more info about HCL in docs.dasharo.com/glossary\r"

  read -p "Do you want to support Dasharo development by sending us logs with hardware configuration? [N/y] "
  case ${REPLY} in
    yes|y|Y|Yes|YES)
      export SEND_LOGS="true"
      echo "Thank you for contributing to the Dasharo development!"
    ;;
    *)
    export SEND_LOGS="false"
      echo "Logs will be saved in root directory."
      echo "Please consider supporting Dasharo by sending the logs next time."
  esac
}

dasharo_hcl_report() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be started as root!"
    exit 1
  fi

  print_hcl_disclaimer

  if [ -d ${REPORT_DIR} ]; then
    rm -rf ${REPORT_DIR}
  fi

  mkdir -p ${REPORT_DIR}
  echo "Getting hardware information. It will take a few minutes..."
  echo "Please be patient, and do not interrupt this process."
  execute_command "lspci -nnvvvxxxx" "lspci" "PCI configuration space and topology"
  execute_command "lsusb -vvv" "lsusb" "USB devices and topology"
  execute_command "superiotool -deV" "superiotool" "Super I/O configuration"
  execute_command "ectool -ip" "ectool" "EC configuration"
  execute_command "msrtool" "msrtool" "MSRs"
  execute_command "dmidecode" "dmidecode" "SMBIOS tables"
  execute_command "biosdecode" "biosdecode" "BIOS information"
  execute_command "nvramtool -x" "nvramtool" "CMOS NVRAM"
  execute_command "inteltool -a" "inteltool" "Intel configuration registers"
  execute_command "dmesg" "dmesg" "kernel dmesg"
  execute_command "acpidump" "acpidump" "ACPI tables"
  execute_command "touchpad-info" "touchpad" "Touchpad information"
  execute_command "decode-dimms" "decode-dimms" "DIMMs information"
  execute_command "cbmem" "cbmem" "CBMEM table information"
  execute_command "find `realpath /sys/class/tpm/tpm*` -type f -print -exec cat {} \;" "tpm_version" "TPM information"
  execute_command "mei-amt-check" "amt-check" "AMT information"
  execute_command "intelmetool" "intelmetool" "ME information"
  execute_command \
    "intelp2m -file ${REPORT_DIR}/inteltool.log -fld cb -i -p snr -o ${REPORT_DIR}/gpio_snr.h && \
     intelp2m -file ${REPORT_DIR}/inteltool.log -fld cb -i -p cnl -o ${REPORT_DIR}/gpio_cnl.h && \
     intelp2m -file ${REPORT_DIR}/inteltool.log -fld cb -i -p apl -o ${REPORT_DIR}/gpio_apl.h && \
     intelp2m -file ${REPORT_DIR}/inteltool.log -fld cb -i -p lbg -o ${REPORT_DIR}/gpio_lbg.h" \
    "intelp2m" "GPIO configuration C header files"

  log echo "Dumping Audio devices configuration..."

  # This is a workaround to soundcard's files absence in short time after booting.
  # Thread is continued here https://github.com/Dasharo/dasharo-issues/issues/247
  for t in {1..12}
  do
    SND_HW_FILES=/sys/class/sound/card0/hw*/init_pin_configs
    SND_CODEC_FILES=/proc/asound/card0/codec#*
    SND_HW_FILE=`echo $SND_HW_FILES | cut -d ' ' -f 1`
    SND_CODEC_FILE=`echo $SND_CODEC_FILES | cut -d ' ' -f 1`

    if [ -f "${SND_HW_FILE}" ] && [ -f "${SND_CODEC_FILE}" ]; then
      break
    else
      sleep 5
      if [ $t -eq 12 ]; then
        log "Sound card files are missing!"
      fi
    fi
  done

  for x in /sys/class/sound/card0/hw*; do cat "$x/init_pin_configs" > ${REPORT_DIR}/pin_"$(basename "$x")" 2> ${REPORT_DIR}/pin_"$(basename "$x")".err.log; done
  for x in /proc/asound/card0/codec#*; do cat "$x" > ${REPORT_DIR}/"$(basename "$x")" 2> ${REPORT_DIR}/"$(basename "$x")".err.log; done
  update_summary "Audio devices configuration" "/dev/null" "/dev/null" "true"

  log "Dumping CPU info..."
  execute_command "cat /proc/cpuinfo" "cpuinfo" "CPU info"
  execute_command "cat /proc/ioports" "ioports" "I/O ports"
  execute_command "cat /sys/class/input/input*/id/bustype" "input_bustypes" "Input bus types"
  execute_command "flashrom -V -p internal:laptop=force_I_want_a_brick -r ${ROM_FILE}" "flashrom_read" "ROM file"

  log "Probing all I2C buses..."
  MAX_I2C_ID=$(i2cdetect -l | awk 'BEGIN{c1=0} //{c1++} END{print "",--c1}')
  for bus in $(seq 0 "$MAX_I2C_ID");
  do
    echo "I2C bus number: $bus" >> ${REPORT_DIR}/i2cdetect.log 2>> ${REPORT_DIR}/i2cdetect.err.log
    i2cdetect -y "$bus" >> ${REPORT_DIR}/i2cdetect.log 2>> ${REPORT_DIR}/i2cdetect.err.log
  done
  update_summary "I2C bus" "${REPORT_DIR}/i2cdetect.log" "${REPORT_DIR}/i2cdetect.err.log" "false"

  log "Decompiling ACPI tables..."
  mkdir -p ${REPORT_DIR}/acpi
  if pushd ${REPORT_DIR}/acpi &> /dev/null; then
    acpixtract -a ../acpidump.log &>/dev/null
    iasl -d ./*.dat &>/dev/null
    popd &> /dev/null
  fi
  update_summary "ACPI tables" "/dev/null" "/dev/null" "true"

  # next two echo cmds helps with printing
  echo
  echo

  echo "Dasharo HCL report summary:" >> ${SUMMARY_FILE}
  echo -e "\nLegend:" >> ${SUMMARY_FILE}
  echo -e [$GREEN"OK"$NORMAL]"\t\t Data get successfully" >> ${SUMMARY_FILE}
  echo -e [$YELLOW"UNKNOWN"$NORMAL]"\t summary is unknown" >> ${SUMMARY_FILE}
  echo -e [$RED"ERROR"$NORMAL]"\t\t Error during getting data\n" >> ${SUMMARY_FILE}

  if [ "${VERBOSE}" = "true" ]; then
    cat "${SUMMARY_FILE}"
  fi

  # MAC address of device that is used to connect the internet
  # it could return none only when there is no internet connection but
  # in those cases report will be stored locally only
  UUID_STRING=`cat /sys/class/net/$(ip route show default | head -1 | awk '/default/ {print $5}')/address`
  # next two values are hardware related so they will be always the same
  UUID_STRING+="_${SYS_PN}_${SYS_MANUF}"

  # using values from above should generate the same uuid all the time if only
  # the MAC address will not change
  UUID=$(uuidgen -n @x500 -N "${UUID_STRING}" -s)

  # Create name for generated report
  REPORT_NAME="${SYS_MANUF}_${SYS_PN}_${BIOS_VERSION}_${UUID}"
  REPORT_NAME+="_$(date +'%Y_%m_%d_%H_%M_%S_%N')"
  REPORT_NAME="${REPORT_NAME// /_}.tar.gz"
  REPORT_PATH="/tmp/${REPORT_NAME}"

  log "Creating archive with ${REPORT_DIR}..."

  # Remove MAC address from ${REPORT_DIR} as sensitive data
  local _mac_addr=`cat /sys/class/net/$(ip route show default | head -1 | awk '/default/ {print $5}')/address`
  # Find files containing the MAC address
  local _files_with_mac_addr=$(grep -l "${_mac_addr}" "${REPORT_DIR}/*" 2> /dev/null)
  if [ -n "$_files_with_mac_addr" ]; then
    for file in $_files_with_mac_addr; do
      sed -i $file 's/'${_mac_addr}'/MAC ADDRESS REMOVED/g'
    done
  fi
  tar -zcvf "${REPORT_PATH}" "${REPORT_DIR}" &> /dev/null

  echo "Done! ${REPORT_DIR} saved to: ${REPORT_PATH})"

  if [ "${SEND_LOGS}" = "true" ]; then
    echo "Sending ${REPORT_DIR} to 3mdeb cloud..."
    cloudsend.sh \
      -e \
      -q \
      "${REPORT_PATH}" \
      "${FULL_UPLOAD_URL}"
    if [ "$?" -ne "0" ]; then
      echo "Failed to send ${REPORT_DIR} to the cloud"
      echo -e "Something may be wrong with Dasharo SE credentials. Please enter
               \rthem again and make sure that there is no typo."
      exit 1
    fi
    echo "Thank you for supporting Dasharo!"
  fi
}
