#!/bin/bash
set -ouex pipefail

update-mime-database /usr/share/mime
gdk-pixbuf-query-loaders-64 --update-cache
gtk-update-icon-cache /usr/share/icons/hicolor
gtk-update-icon-cache --force --ignore-theme-index /usr/share/icons/luna

systemctl --global preset-all
systemctl preset-all
