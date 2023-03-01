#!/usr/bin/env bash

set -Eeuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# shellcheck source=./src/functions.sh
source "${script_dir}/functions.sh"

while : ; do
  get_hw_info
  show_menu
done
