#!/bin/bash

set -ouex pipefail

systemctl enable libvirtd.service
systemctl enable winblues-user-init.service
