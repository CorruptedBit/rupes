#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# Install packages

## dnf5's config-manager/copr plugins aren't necessarily installed by default.
dnf5 install -y dnf5-plugins

## Similar to uCore: podman-compose, firewalld, tailscale, distrobox, flatpak
dnf5 install -y podman-compose firewalld tailscale distrobox flatpak

## just (task runner) -- our own recipes live in system_files/usr/share/just/,
## invoked via the `hjust` alias (system_files/usr/bin/hjust).
dnf5 install -y just

## Gaming basics that are already plain Fedora packages -- no COPR/RPM Fusion
## needed. Steam itself is installed on-demand via Flatpak (`hjust
## install-steam`), since Fedora doesn't ship a native Steam RPM and the
## Flatpak build is the well-supported path on an immutable/ostree base.
## gamescope/mangohud are deliberately not baked in: the Steam Flatpak can't
## see host binaries and uses its own sandbox extensions instead.
dnf5 install -y gamemode mesa-vulkan-drivers

## ratbagd: system D-Bus daemon for configuring gaming mice (Piper etc.)
dnf5 install -y libratbag-ratbagd

## Terminal and launcher referenced by Fedora's default sway config
## ($term = foot, $menu = rofi; rofi-wayland is now merged into plain rofi).
dnf5 install -y foot rofi

## VsCode from Microsoft
rpm --import https://packages.microsoft.com/keys/microsoft.asc

cat << 'EOF' > /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

dnf5 install -y code

## Terra Software (Zed editor)
## Plain fedora-bootc doesn't ship the Terra repo files like ublue-os images
## do, so bootstrap it ourselves (see https://docs.terrapkg.com/usage/installing/).
dnf5 install -y --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" terra-release terra-gpg-keys
dnf5 install -y zed
dnf5 config-manager setopt terra.enabled=0
rm -f /etc/yum.repos.d/terra*.repo

#### Example for enabling a System Unit File
systemctl enable podman.socket

## ratbagd is D-Bus activated (Type=dbus); enabling just creates its
## dbus-org.freedesktop.ratbag1.service alias so activation resolves.
systemctl enable ratbagd.service

## Add Flathub as a system-wide flatpak remote on first boot (Fedora Atomic
## Desktops, like plain Fedora, only ship their own remote by default, not
## Flathub -- see system_files/usr/lib/systemd/system/flathub-setup.service).
systemctl enable flathub-setup.service
