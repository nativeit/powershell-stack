#!/bin/bash

current_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
current_script_name=$(basename ${0##*/} .sh)

papertrail_token=$(pass Mozilla/papertrail/grenade-token)

gem install papertrail
echo "token: ${papertrail_token}" > /tmp/papertrail.yml

for manifest in $(ls ${current_script_dir}/../userdata/Manifest/gecko-*.json); do
  workerType=$(basename ${manifest##*/} .json)
  papertrail-add-group -g worker/${workerType} -w *.${workerType}.* -c /tmp/papertrail.yml
done

rm -f /tmp/papertrail.yml
