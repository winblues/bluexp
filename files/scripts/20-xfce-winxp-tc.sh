#!/usr/bin/env bash

set -xueo pipefail

dnf5 install -y $(cat packages/xfce-winxp-tc/build-deps.txt)

XFCE_WINXP_TC_VERSION="4f73e4a740041635eecd30abccc2fdafabb21582"

mkdir -p /tmp/xfce-winxp-tc
cd /tmp/xfce-winxp-tc
git clone --depth 1 https://github.com/rozniak/xfce-winxp-tc.git
cd xfce-winxp-tc
git checkout $XFCE_WINXP_TC_VERSION
bash packaging/buildall.sh

rpm-ostree install xptc/*/rpm/std/x86_64/fre/wintc-*.rpm

