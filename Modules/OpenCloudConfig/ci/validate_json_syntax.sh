#!/bin/bash -e

for manifest in $(ls ./OpenCloudConfig/userdata/Manifest/gecko-*.json ./OpenCloudConfig/userdata/Manifest/relops*.json); do
  echo "[opencloudconfig $(date --utc +"%F %T.%3NZ")] validating manifest ${manifest}"
  jsonlint ${manifest}
done