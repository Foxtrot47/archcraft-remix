#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -e -u
shopt -s extglob

# Warning: customize_airootfs.sh is deprecated! Support for it will be removed in a future archiso version.

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

# Sudo to allow no password
sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
chown -c root:root /etc/sudoers
chmod -c 0440 /etc/sudoers

# Get the best mirrorlist.
reflector --verbose --sort score --save /etc/pacman.d/mirrorlist

## Distro Info
cat > "/etc/os-release" <<- EOL
	NAME="Archcraft"
	PRETTY_NAME="Archcraft"
	ID=arch
	BUILD_ID=rolling
	ANSI_COLOR="38;2;23;147;209"
	HOME_URL="https://archcraft-os.github.io/"
	LOGO=archcraft
EOL

cat > "/etc/issue" <<- EOL
	Archcraft \r (\l)
EOL

# Enable multilib repository.
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

## Append 3rd party repositories to pacman.conf
cat >> "/etc/pacman.conf" <<- EOL

## Archcraft Repository
[archcraft]
SigLevel = Optional TrustAll
Server = https://archcraft-os.github.io/archcraft-pkgs/\$arch

## Chaotic-AUR Repository
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist

EOL

## Hide Unnecessary Apps
adir="/usr/share/applications"
apps=(avahi-discover.desktop bssh.desktop bvnc.desktop compton.desktop echomixer.desktop \
envy24control.desktop exo-mail-reader.desktop exo-preferred-applications.desktop feh.desktop gparted.desktop \
hdajackretask.desktop hdspconf.desktop hdspmixer.desktop hwmixvolume.desktop lftp.desktop \
libfm-pref-apps.desktop lxshortcut.desktop lstopo.desktop mimeinfo.cache \
networkmanager_dmenu.desktop nm-connection-editor.desktop pcmanfm-desktop-pref.desktop \
qv4l2.desktop qvidcap.desktop stoken-gui.desktop stoken-gui-small.desktop thunar-bulk-rename.desktop \
thunar-settings.desktop thunar-volman-settings.desktop yad-icon-browser.desktop)

for app in "${apps[@]}"; do
	if [[ -f "$adir/$app" ]]; then
		sed -i '$s/$/\nNoDisplay=true/' "$adir/$app"
	fi
done

## Other Stuff
cp /usr/bin/networkmanager_dmenu /usr/local/bin/nmd && sed -i 's/config.ini/nmd.ini/g' /usr/local/bin/nmd
sed -i -e 's/Inherits=.*/Inherits=Hybrid_Light,Papirus,Moka,Adwaita,hicolor/g' /usr/share/icons/Arc/index.theme
rm -rf /usr/share/xsessions/openbox-kde.desktop /usr/share/applications/xfce4-about.desktop /usr/share/pixmaps/archlinux.png /usr/share/pixmaps/archlinux.svg

## Enable some services.
services=(ananicy earlyoom)
for service in "${services[@]}"; do
    systemctl enable $service
done
