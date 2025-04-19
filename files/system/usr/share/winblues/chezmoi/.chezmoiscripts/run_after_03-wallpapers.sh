#!/bin/bash
set -exuo pipefail

. "${WINBLUES_CHEZMOI_ORIGINAL_ENV_FILE}"

# TODO: check user's config to see if they don't want us to manage wallpapers

# Allow setting a different wallpaper per workspace
xfconf-query --create -c 'xfce4-desktop' -p '/backdrop/single-workspace-mode' --type 'bool' --set 'false'

# The rest of the workspaces are tiled images
images=(
  "/usr/share/backgrounds/wintc/bliss.jpg"
  "/usr/share/backgrounds/wintc/follow.jpg"
  "/usr/share/backgrounds/wintc/redmoon.jpg"
)

workspace_id=0
for image in "${images[@]}"; do
  xfconf-query --channel xfce4-desktop --list |
    grep "workspace${workspace_id}/color-style" |
    xargs -I{} xfconf-query --create -c 'xfce4-desktop' -p {} --type 'int' --set 0

  xfconf-query --channel xfce4-desktop --list |
    grep "workspace${workspace_id}/image-style" |
    xargs -I{} xfconf-query --create -c 'xfce4-desktop' -p {} --type 'int' --set 3

  xfconf-query --channel xfce4-desktop --list |
    grep "workspace${workspace_id}/last-image" |
    xargs -I{} xfconf-query --create -c 'xfce4-desktop' -p {} --type 'string' --set "$image"

  ((workspace_id++))
done
