#!/bin/bash

echo "Welcome to snapper setup script for void"
echo "by Oku"

sleep 2

snapper_setup () {
    echo "Setting up snapper"
    sudo umount /.snapshots
    sudo rm -r /.snapshots
    sudo snapper -c root create-config /
    sudo btrfs subvolume delete /.snapshots
    sudo mkdir /.snapshots
    sudo mount -a
    sudo chmod 750 /.snapshots
    echo "Put your user in to the config file (ALLOW_USERS="yourusername") and config your cleanup schedule"
    sleep 5
    sudo vim /etc/snapper/configs/root
    echo "Installing cronie for automatic snapshots"
    sudo xbps-install cronie
    echo "Enabling services"
    sleep 2
    sudo ln -sr /etc/sv/{snapperd,grub-btrfs,cronie,crond} /var/service
    echo "Setting up permisions"
    sleep 3
    sudo chmod a+rx /.snapshots
    sudo chown :$USER /.snapshots
    echo "Set up complete ... reboot the system"
}

snapper_setup

echo "Done ..., thank you for use this script"
