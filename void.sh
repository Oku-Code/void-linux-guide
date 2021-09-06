#!/bin/bash

exit=0

#Steps to do on Void

void_base_setup(){
    echo 'Configuring void...'
    ln -s /usr/share/zoneinfo/America/Bogota /etc/localtime
    vim /etc/rc.conf
    vim /etc/default/libc-locales
    xbps-reconfigure -f glibc-locales
    echo "hostname" >> /etc/hostname
    echo "127.0.0.1 locahost" >> /etc/hosts
    echo "::1   locahost" >> /etc/hosts
    echo "127.0.1.1 username.localdomain   hostname" >> /etc/hosts
    vim /etc/hosts
    passwd
    useradd -mG wheel usename
    passwd username
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=VOID
    update-grub
}

# Why they don't have a easy way to generate the fstab file?

void_fstab_file(){
    echo 'Rename the file fstab.backup to the fstab and change the UUID, also verify the IDs for the fstab file'
    sleep 4
    mv /void-setup-guide/fstab.backup /etc/
    blkid
}

#Choose your favorite stuff 

void_post_setup(){
    echo "Enabling internet connection"
    sudo ln -sr /etc/sv/{dhcpcd-eth0,dhcpcd} /var/service
    sleep 5

    echo "Installing packages"
    sudo xbps-install -S xorg vpm void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree snapper kde5 dolphin htop gparted gnome-disk-utility gwenview sddm okular konsole spectacle notepadqq alacritty firefox chromium dejavu-fonts-ttf font-bh-ttf font-fira-ttf font-hack-ttf font-ibm-plex-ttf font-mplus-ttf fonts-roboto-ttf liberation-fonts-ttf noto-fonts-ttf noto-fonts-ttf-extra xdg-user-dirs xdg-utils bash-completion flatpak libreoffice libreoffice-kde pulseaudio xdg-utils xdg-user-dirs

    echo "Enabling services"
    sudo ln -srf /etc/sv/{dhcp,dbus,polkit,elogind,acpid,snapperd,grub-btrfs,sshd} /var/service
    sleep 2
    echo "Installing nonfree packages"
    sudo vpm install intel-ucode p7zip unrar p7zip-unrar
    sleep 2
    echo "Adding flatpak repo"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sleep 2
    echo "Reconfigure the system"
    sudo vpm reconfigure
}

while [ $exit -eq 0 ]
do
    echo "Welcome to setup script for Void Linux"
    echo "by Oku"
    echo "1) Base Setup"
    echo "2) Void Fstab"
    echo "3) Post Setup => Do this after install void base system"
    echo "4) Exit"
echo "Select an option: "
read option

case $option in
    1) void_base_setup;;
    2) void_fstab_file;;
    3) void_post_setup;;
    4) exit=1;;
    *) echo "Option not found, select a correct option";;
esac
done

echo "Done... Bye"
# sudo ln -s /etc/sv/sddm /var/service
