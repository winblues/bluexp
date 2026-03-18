#!/usr/bin/env bash

set -xueo pipefail

# shellcheck disable=SC1091
source "${CONFIG_DIRECTORY}/xfce-winxp-tc.env"

dnf5 install -y golang-oras

RPM_DIR=$(mktemp -d)
cd "$RPM_DIR"

FEDORA_MAJOR_VERSION=$(awk -F= '/^VERSION_ID/ {print $2}' /etc/os-release)
oras pull "ghcr.io/winblues/xfce-winxp-tc-rpms:${XFCE_WINXP_TC_VERSION}-${FEDORA_MAJOR_VERSION}"

dnf5 install ./*.rpm

plymouth-set-default-theme bootvid
