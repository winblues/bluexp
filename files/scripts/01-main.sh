#!/bin/bash

set -ouex pipefail

systemctl enable libvirtd.service
systemctl enable winblues-user-init.service

# Nerd fonts
curl -Lo /tmp/jetbrains.tar.xz https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.tar.xz
cd /usr/share/fonts
mkdir jetbrains-mono-nerdfonts
cd jetbrains-mono-nerdfonts
tar xf /tmp/jetbrains.tar.xz
fc-cache -v
