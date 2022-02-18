#!/bin/bash

tooltool_token_path=${HOME}/.tooltool.token
tooltool_url=https://tooltool.mozilla-releng.net
wrk_dir=$(pwd)
tmp_dir=$(mktemp -d)

fg_black=`tput setaf 0`
fg_red=`tput setaf 1`
fg_green=`tput setaf 2`
fg_yellow=`tput setaf 3`
fg_blue=`tput setaf 4`
fg_magenta=`tput setaf 5`
fg_cyan=`tput setaf 6`
fg_white=`tput setaf 7`
reset=`tput sgr0`

cd ${tmp_dir}
if [ ! -f "${tmp_dir}/tooltool.py" ]; then
  curl -s -o ${tmp_dir}/tooltool.py https://raw.githubusercontent.com/mozilla-releng/tooltool/master/client/tooltool.py
  echo "$(tput dim)[${current_script_name} $(date --utc +"%F %T.%3NZ")]${reset} tooltool client downloaded to ${tmp_dir}/tooltool.py"
fi

curl -sL https://gist.githubusercontent.com/grenade/109bfd61a663902236e1d3f6530dec55/raw/manifest.json?$(uuidgen) | jq -r '.[] | @base64' | while read item; do
  _jq_decode() {
    echo ${item} | base64 --decode | jq -r ${1}
  }
  url=$(_jq_decode '.url')
  filename=$(_jq_decode '.filename')
  if curl -sL -o ${tmp_dir}/${filename} ${url}; then
    echo "$(tput dim)[${current_script_name} $(date --utc +"%F %T.%3NZ")]${reset} downloaded ${tmp_dir}/${filename} from ${url}"
    computed_sha512=$(sha512sum "${tmp_dir}/${filename}" | { read sha512 _; echo ${sha512}; })
    if curl --header "Authorization: Bearer $(cat ${tooltool_token_path})" --output /dev/null --silent --head --fail ${tooltool_url}/sha512/${computed_sha512}; then
      echo "$(tput dim)[${current_script_name} $(date --utc +"%F %T.%3NZ")]${reset} found ${filename} in tooltool with sha ${computed_sha512}"
    else
      python ${tmp_dir}/tooltool.py add --visibility internal "${tmp_dir}/${filename}" -m ${tmp_dir}/manifest.tt
      echo "$(tput dim)[${current_script_name} $(date --utc +"%F %T.%3NZ")]${reset} failed to find ${filename} in tooltool with sha ${computed_sha512}"
    fi
  else
    echo "$(tput dim)[${current_script_name} $(date --utc +"%F %T.%3NZ")]${reset} failed to download ${tmp_dir}/${filename} from ${url}"
  fi
done

if [ -f ${tmp_dir}/manifest.tt ] && [ -s ${tmp_dir}/manifest.tt ] && python ${tmp_dir}/tooltool.py validate -m ${tmp_dir}/manifest.tt; then
  python ${tmp_dir}/tooltool.py upload --url ${tooltool_url} --authentication-file=${tooltool_token_path} --message "Bug 1342892 - OCC component: ${filename}" -m ${tmp_dir}/manifest.tt
  rm -f ${tmp_dir}/manifest.tt
else
  echo "$(tput dim)[${current_script_name} $(date --utc +"%F %T.%3NZ")]${reset} tooltool upload skipped due to manifest absence or validation failure for ${tmp_dir}/manifest.tt"
fi
cd ${wrk_dir}
rm -rf ${tmp_dir}