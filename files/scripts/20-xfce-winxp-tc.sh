#!/usr/bin/env bash

set -xueo pipefail

# Ideally, we would build and package this outside of the image build process.
# However, it's probably not possible to package this in on Fedora's COPR
# because of licensing concerns with some of the assets
#
# TODO: package this using a separate GitHub repo maybe?

dnf5 install -y $(cat packages/xfce-winxp-tc/build-deps.txt)

XFCE_WINXP_TC_VERSION="4f73e4a740041635eecd30abccc2fdafabb21582"

mkdir -p /tmp/xfce-winxp-tc
cd /tmp/xfce-winxp-tc
git clone https://github.com/rozniak/xfce-winxp-tc.git
cd xfce-winxp-tc
git checkout $XFCE_WINXP_TC_VERSION
bash packaging/buildall.sh

rpm-ostree install xptc/*/rpm/std/x86_64/fre/wintc-*.rpm

# TODO: remove build packages

plymouth-set-default-theme bootvid
