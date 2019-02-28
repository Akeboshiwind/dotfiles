#!/bin/bash


# Check we are root
# TODO: maybe don't run as root
## It created all the config stuff in the /root/ directory
if [[ $EUID -ne 0 ]]; then
    echo "You must be a root user" 2>&1
    exit 1
fi



# Install yay package manager
#git clone https://aur.archlinux.org/yay.git
#cd yay
#makepkg -si
#cd ..
#rm -rf yay



# Update System
yay -Syu


## Stow
yay -S --noconfirm stow
stow bash
stow tmux
stow bin



## GPG
### Automatically refresh keys over tor
yay -S --noconfirm parcimonie-sh-git
systemctl enable parcimonie.sh@all-users
systemctl start parcimonie.sh@all-users
stow gpg


## Keybinds
### Install xmodmap
yay -S --noconfirm xorg-xmodmap
stow x



# TODO: zen kernel?
# TODO: Switch hard drive sheduler



# Graphics
## XOrg
yay -S --noconfirm xorg-server
## Graphics Driver
yay -S --noconfirm nvidia
## Display Manager
yay -S --noconfirm lightdm
yay -S --noconfirm lightdm-gtk-greetek
## Window Manager
yay -S --noconfirm i3-gaps
yay -S --noconfirm xorg-xrandr
yay -S --noconfirm xorg-xhost
yay -S --noconfirm xorg-xrdb
yay -S --noconfirm feh
yay -S --noconfirm python-pywal
yay -S --noconfirm nerd-fonts-complete
yay -S --noconfirm polybar
yay -S --noconfirm rofi
yay -S --noconfirm i3ass
yay -S --noconfirm ranger
yay -S --noconfirm w3m
yay -S --noconfirm scrot
# TODO: compton
### Give permissions to polybar
#chmod +x ~/.config/linux/polybar/launch.sh
stow polybar
stow rofi
stow i3
stow ranger
## Enable and start display manager
systemctl enable lightdm
systemctl start lightdm



# Input
yay -S xf86-input-libinput
stow inputrc



# Sound
## TODO: Read the arch linux pulseaudio wiki page
yay -S --noconfirm pulseaudio
yay -S --noconfirm pulseaudio-alsa
yay -S --noconfirm lib32-libpulse
yay -S --noconfirm lib32-alsa-plugin
yay -S --noconfirm pavucontrol



# Network
yay -S --noconfirm networkmanager
yay -S --noconfirm nm-connection-editor
yay -S --noconfirm network-manager-applet


# Time
yay -S --noconfirm chrony
yay -S --noconfirm networkmanager-dispatcher-chrony
## Copy config file (doesn't like symlinks)
#cp ~/.config/linux/chrony.conf /etc/chrony.conf
#TODO: check
stow chrony
## Stop systemd-timesyncd
systemctl stop systemd-timesyncd
systemctl disable systemd-timesyncd
## Start chronyd
systemctl enable chronyd
systemctl start chronyd



# Install packages
## Git
#yay -S --noconfirm git



## Emacs
yay -S --noconfirm emacs
### Font
#### Requires 'Extra' package repository
yay -S --noconfirm ttf-hack
### LaTeX
yay -S --noconfirm texlive-most
#### pdf->png conversion for resume
yay -S --noconfirm ghostscript
yay -S --noconfirm imagemagick
### Spacemacs
#### Remove potential .emacs and .emacs.d/ files and folders
rm -rf ~/.emacs.d/
rm -rf ~/.emacs
#### Clone spacemacs
git clone -b develop https://github.com/syl20bnr/spacemacs ~/.emacs.d
stow spacemacs



## Dropbox
yay -S --noconfirm dropbox
### Disable automatic updates
rm -rf ~/.dropbox-dist
install -dm0 ~/.dropbox-dist
### Autostart on boot
systemctl enable dropbox@ake



## vim
yay -S --noconfirm vim
yay -S --noconfirm vim-plug
stow vim



## Docker
yay -S --noconfirm docker
yay -S --noconfirm docker-compose
systemctl enable docker.service
systemctl start docker.service
stow docker



## ssh
yay -S --noconfirm openssh
### Prompt reminder to get ssh key and generate public key
### Generate command:
#### ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub



## st
git clone git@github.com:Akeboshiwind/st.git
cd st
makepkg -sif
cd ..
rm -rf st



## fish
yay -S --noconfirm fish
chsh -s /usr/bin/fish
stow fish



## Printing
### Setup hostname resolution
yay -S --noconfirm nss-mdns
ln -s ~/.config/linux/nsswitch.conf /etc/nsswitch.conf
### Install Avahi service discovery
yay -S --noconfirm avahi
systemctl stop systemd-resolved.service
systemctl disable systemd-resolved.service
systemctl enable avahi-daemon.service
systemctl start avahi-deamon.service
### Install CUPS printing system
yay -S --noconfirm cups
yay -S --noconfirm cups-pdf
systemctl enable org.cups.cupsd.service
systemctl start org.cups.cupsd.service
### Install printer drivers
yay -S --noconfirm hplip
#### Foomatic
yay -S --noconfirm foomatic-db-engine
yay -S --noconfirm foomatic-db
yay -S --noconfirm foomatic-db-ppds
yay -S --noconfirm foomatic-db-nonfree-ppds
yay -S --noconfirm foomatic-db-gutenprint-ppds
stow linux-print -t /




## Others
yay -S --noconfirm audacity
yay -S --noconfirm exa
yay -S --noconfirm notify-osd # Get's notify-send working
yay -S --noconfirm pacman-contrib
yay -S --noconfirm discord
yay -S --noconfirm google-chrome
yay -S --noconfirm jdk
yay -S --noconfirm jre
yay -S --noconfirm keeweb-desktop
yay -S --noconfirm mumble
yay -S --noconfirm noto-fonts
yay -S --noconfirm noto-fonts-emoji
yay -S --noconfirm p7zip
yay -S --noconfirm plex-media-player
yay -S --noconfirm spotify
yay -S --noconfirm the_platinum_searcher



# TODO: Setup Displays using xrandr
## Edit i3 config
#wal -i "~/Dropbox/documents/Pictures/Backgrounds/General/ background/Anime&Manga/4qmKPh8.png"
## TODO: use xresources-theme for linux to theme spacemacs
## TODO: Setup bars in polybar
## TODO: Theme?
### Icons
### Fonts
#### Same for all?
### Colours
## TODO: Power Management
### What to do on:
#### Laptop close
#### Power button press
#### Low battery power
### Suspend vs Hibernate
# Login to places
## Dropbox
## Google Chrome
## Franz
## Keeweb
## Spotify
