#!/usr/bin/env bash

set -xueo pipefail

# shellcheck disable=SC1091
source "${CONFIG_DIRECTORY}/xfce-winxp-tc.env"

dnf5 install -y oras-cli

RPM_DIR=$(mktemp -d)
cd "$RPM_DIR"

oras pull "ghcr.io/winblues/xfce-winxp-tc-rpms:${XFCE_WINXP_TC_VERSION}"

rpm-ostree install ./*.rpm

plymouth-set-default-theme bootvid
