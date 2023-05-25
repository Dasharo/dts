#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# set -x

# shellcheck source=./src/env.sh
source "${script_dir}/env.sh"
# shellcheck source=./src/functions.sh
source "${script_dir}/functions.sh"
# shellcheck source=./src/dasharo-hcl-report.sh
source "${script_dir}/dasharo-hcl-report.sh"

while : ; do
  get_hw_info
  show_menu
done
