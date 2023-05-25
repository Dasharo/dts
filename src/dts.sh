#!/usr/bin/env bash

#set -Eeuo pipefail
set -x

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# shellcheck source=./src/functions.sh
source "${script_dir}/env.sh"
source "${script_dir}/functions.sh"
source "${script_dir}/dasharo-hcl-report"

while : ; do
  get_hw_info
  show_menu
done
