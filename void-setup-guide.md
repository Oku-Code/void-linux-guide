# Void linux guide for btrfs file systems with snapper

Hello and welcome, here i'm going to explain the basics about to setup, configure and install **void** an independent linux distribution, there are some tricks to get work with btrfs file system, in this case i recommend this guide if you want to have the following:

1. Btrfs file system with subvolumes
2. Create snapshots to maintain copies for your current system
3. Configure snapper, it's relative easy on this distribution
    - **Note**: snapper on void don't work automatically, i mean is not like Archlinux that you can generate snapshots if you update or remove packages, also this distribution don't have **snapper_gui** you need to manage your snapshots manually.

## Table of contents

The document contains the following: 

1. [First steps](#first-steps)
    - [Preparing the iso file](#preparing-the-iso-file)
2. [Installing Void](#installing-void)
    - [Connecting to the network](#connecting-to-the-network)
    - [Updating xbps package manager](#updating-xbps-package-manager)
    - [Partitioning your disk](#partitioning-your-disk)
    - [Installing base system](#installing-base-system)
3. [Void Chroot](#void-chroot)
4. [Configure snapper on void](#configure-snapper-on-void)
5. [Restoring a snapshot](#restoring-a-snapshot)
6. [References](#references)

## First steps

### Preparing the iso file:

So let's start first you need a USB and a Void Linux iso, where you can find it from the official website from void:

- Official Site: [VoidIso](https://voidlinux.org/download/)

    - **Note**: this guide goes to _glibc_ version of void.

Now let's create the USB live iso, there are some many options to perform this task, most recommended programs are:

- **Windows**: [Rufus](https://rufus.ie/en/), [Balena etcher](https://www.balena.io/etcher/), [Ventoy](https://www.ventoy.net/en/download.html)
- **MacOS**: [Balena etcher](https://www.balena.io/etcher/), [Ventoy](https://www.ventoy.net/en/download.html)
- **Linux**: [Balena etcher](https://www.balena.io/etcher/), [Ventoy](https://www.ventoy.net/en/download.html)

Boot into your iso file:

- In some computers you need to press **F11** or **Del** key to enter into the BIOS, in lenovo laptops use the **Novo button** to enter the boot menu, select the uefi memory and your are in.

## Installing Void

There are two ways to install void one is to type `void-installer` when you are loggin as a root user, the other way is more complicated but here i'm tell you how to do it using `chroot`.

- _tip_: Void is well documented by their developers, so check it out [here](https://docs.voidlinux.org/about/index.html) if you have some trouble with the installation process.

### Connecting to the network:

Use the `nmtui` utility if you have a WLAN connection, but if you have a internet cable connection you don't need to do this


### Updating xbps package manager:  

So, here we start updating the xbps package manager to this type the following commands:

- `xbps-install -Su xbps`: This syncronize the system and perform an update to xbps package manager.

### Partitioning your disk:

Next is to use `cfdisk /dev/sdx` to create the partitions:

- **Note**: if you dont know how your disk is assigned use `lsblk` command to know it.
- You need create the `UEFI partition` and the `main partition`, with cfdisk command you can do it.
- Change the code to efi partition to `ef00`, and write the changes to the disk.
- Also if you have a gpt label, instead install the `gptfdisk` using the `xbps-install -Sy gptfdisk` to use gdisk or cgdisk to perform operations on your disks.

#### Creating the filesystems:

Its simple you need to use `mkfs.vat /dev/sdx1` for the Efi partition and `mkfs.btrfs /dev/sdx2` for the main partition.

- __Tip__: nvme partitions on linux are assigned as: `nvme0n1` for the disk and `nvme0n1p1` for partitions.

#### Creating the subvolumes for btrfs:

Next mount the main partition on `/mnt` and do the following:

- Create the subvolumes: we are using the snapper so you need to create this [scheme](https://wiki.archlinux.org/title/Snapper#Suggested_filesystem_layout).
    - **btrfs subvolumes**: `btrfs subvolume create /mnt/@`
    - Create the other subvolumes with the same command for: `@home`, `@var_log`, `@snapshots`.

#### Mounting the main partition with btrfs option:

Options depends of your disks:

- **HDD**: `mount -o compress=zstd,noatime,space_cache=v2,subvol=@ /dev/sdx2 /mnt`
- **SSD o NVME**: `mount -o compress=zstd,noatime,space_cache=v2,subvol=@,discard=async /dev/sdx2 /mnt`
- **Note**: You can change the compression algoritm in the mount options like `lzo`, also i recommend to leave an empty space for nvme or ssd devices

#### Making the mount directories:

Let's create the directories for the mount points:

- **For efi**: `mkdir -p /mnt/boot/efi`
- **For subvolumes**: `mkdir -p {home,.snapshots}`

#### Mounting the rest of the subvolumes:

And now lets mounted the subvolumes:

- **Home**: `mount -o compress=zstd,noatime,space_cache=v2,subvol=@home /dev/sdx2 /mnt/home`
- **Snapshots**: `mount -o compress=zstd,noatime,space_cache=v2,subvol=@snapshots /dev/sdx2 /mnt/.snapshots`
- **Var_log**: `mount -o compress=zstd,noatime,space_cache=v2,subvol=@var_log /dev/sdx2 /var/log`

> You can easily create a variable for the btrfs options like so: `BTRFS_OPTS=compress=zstd,noatime,space_cache=v2,autodegrag`

#### Mount the efi partition

Finally the efi partition:

- **Efi**: `mount /dev/sdx1 /mnt/boot/efi`

- **Note**: if you attempt to install the system with a disk with gpt labels on an MBR system remember to create a BIOS Boot Partition on your root of you disk
this allows to install the grub bootloader properly

### Installing the base system on Void

Here on void its different, in Arch you have **pacstrap** command, but here you need to setup the following varibles before your bootstraping your installation:

- Defining the main repo varible: `REPO=https://repo-default.voidlinux.org/current`

    - **Note**: if you need to look up your nearest mirror, can you find it on [mirrors](https://docs.voidlinux.org/xbps/repositories/mirrors/index.html) on the void handbook, change the mirror of your preference.

- Defining the archquitecture variable: `ARCH=x86_64`

- Bootstraping the base-system: Now you need to install the system and the packages, here you specify what you want, this is an exmaple:

    - `XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system vim git btrfs-progs networkmanager base-devel efibootmgr ntfs-3g mtools dosfstools grub-btrfs-runit grub-x86_64-efi elogind polkit dbus void-repo-nonfree ` => pick your poison.

- Entering chroot mode, you need mount the following files on to your system:

    - `for dir in dev proc sys run; do mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/dir; done`

> Simplest way in my opinion to mount those files

- Copy DNS config:

    - `cp /etc/resolv.conf /mnt/etc`

- Finally chroot into your install:

    - BTRFS_OPTS=$BTRFS_OPTS `PS1='(chroot) # ' chroot /mnt/ /bin/bash`

- **Note:** this varible will be use it when you are creating the fstab file, better to keep it to make your live easier

### Void Chroot

This is a same process like arch with some exeptions, we review here now:

#### Generating the fstab file:

Here you need to be carefull with the UUID of the disks, if you want to know the specific id use `blkid` command to see the UUIDs.

- Store the UUIDS for the partitions there are created:

    - `UEFI_UUID=$(blkid -s UUID -o value /dev/sdx1)`
    - `ROOT_UUID=$(blkid -s UUID -o value /dev/sdx2)`

> Remember sdx or nvmex is your partition

- Use the cat command to create the fstab file

    - ```
        cat << EOF > /etc/fstab
            UUID=$UEFI_UUID    /boot/efi     vfat     defaults,noatime     0 2
            UUID=$ROOT_UUID    /             btrfs    $BTRFS_OPTS,subvol=@ 0 1 
            UUID=$ROOT_UUID    /home         btrfs    $BTRFS_OPTS,subvol=@home 0 2 
            UUID=$ROOT_UUID    /.snapshots   btrfs    $BTRFS_OPTS,subvol=@snapshots 0 2 
            UUID=$ROOT_UUID    /var/log      btrfs    $BTRFS_OPTS,subvol=@var_log 0 2
            tmpfs              /tmp          tmpfs    defaults,nosuid,nodev     0 0 
        EOF
        ```
> Why i don't know this before :(

#### Configure timezone:

- `ln -sf /usr/share/zoneinfo/America/Bogota /etc/localtime`: this generate the locales.

#### Additional config:

- `vim /etc/rc.conf`: here define the locales, fonts and also the vconsole keymaps

#### Generating the locales:

- `vim /etc/default/libc-locales`: Uncomment your location
- `xbps-reconfigure -f glibc-locales`: Generate locales according with your choice

#### Setting hostname:

- `vim /etc/hostname`: Define your machine name.

#### Configuring the network:

- The configuration on this file is the same like in arch, you can find it [here](https://wiki.archlinux.org/title/Installation_guide#Network_configuration).

```
127.0.0.1   localhost
::1         localhost
127.0.1.1   hostname.localdomain    hostname
```

#### Enable Network Service

- Choose the command depending of your connection:
    - `ln -s /etc/sv/NetworkManager /var/service`: This command enable the internet connection.
    - `ln -s /etc/sv/dhcpcd-eth0 /var/service`: For LAN connections
    - `ln -s /etc/sv/dhcpcd /var/service`: For WLAN connections

#### Enabling the others serivces

- Use the following command: `ln -srf /etc/sv/{dbus,polkit,elogind} /var/service`

#### Create a root password:

- Use `passwd` to create a root password

#### Create a user:

- Use `useradd -mG wheel NAMEOFUSER`
- Use `paswd NAMEOFUSER` to create a new password
- Add the user to the wheel group, `EDITOR=vim visudo` and uncomment `%wheel ALL= (ALL) ALL`

#### Installing the bootloader:

- `grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=VOID`, type this command to install grub.
- `grub-makeconfig -o /boot/grub/grub.cfg`, update grub config or simply type `update grub`.
- **Note:** for MBR partitions, or an gpt label in a MBR system execute the following: `grub-install --target=i386-pc /dev/sdx`

> Notice i'm selecting the volume not the partition, is a common error 

#### Update initramfs

- Finally generate the new installation: `xbps-reconfigure -fa`

From here you need to exit from the chroot mode and a umount all the partitions, and congratulations you **made it** void is installed with btrfs file system.

## Configure snapper on void

In order to use snapper on Void you need to configure it first, so let's do it:

1. Update your system:

    - `sudo xbps-install -Su`

2. Install snapper:

    - `sudo xbps-install -S snapper`

3. Enable snapper service and grub-btrfs service:

    - `ln -srf /etc/sv/{snapperd,grub-btrfs} /var/service`
    - **Note**: grub-btrfs show the snapshots in the grub bootloader and allows you enter on your created snapshots from snapper.

4. Umount the /.snapshots directory:

    - `sudo umount /.snapshots/`

5. Delete the ./snapshots directory:

    - `sudo rm -r /.snapshots`

6. Create the configuration file for snapper, add your current user and configure your snapshots limits schedule:

   - `sudo snapper -c root create-config /`
   - `sudo vim /etc/snapper/configs/root` => Change __ALLOW_USERS=""__ for __ALLOW_USERS="NAMEOFUSER"__
   - If you need to know how to configure your limit schedule go [here](https://wiki.archlinux.org/title/Snapper#Set_snapshot_limits)

7. Delete the /.snapshots subvolume:

    - `sudo btrfs subvolume delete /.snapshots`

8. Create a new /.snapshots directory : 

    - `sudo mkdir /.snapshots`

9. Mount the new directory /.snapshots on @snapshots subvolume: 

    - `sudo mount -a`

10. Change the permision for the folder and the user access:

    - `sudo chmod a+rx /.snapshots` => Change the permission of the folder
    - `sudo chown :username /.snapshots` => Change the permission of the user

11. Verify the creation of the snapshots:

    - `snapper -c root list` => list the snapshots presents on the snapper config file **in this coase shows only current**.
    - `sudo snapper -c root create -c timeline -d "Test snapshot"` => Create a test snapshot
    - `snapper -c root list` => Listed again with the last created snapshot
    - `sudo snapper delete 1` => And delete the snapshot created
    - If you want more information about the snapper commands you can go to [Snapper Wiki](https://wiki.archlinux.org/title/Snapper#Manual_snapshots).

12. Automating the process using cronie:

    - Install cronie with xbps: `sudo xbps-install -Sy cronie`
    - Enable the service with the symbolic link: `ln -sr /etc/sv/{cronie,crond} /var/service`
    - And you done, check in the grub if there's snapshots of your sistem  

## Restoring a snapshot 

Now let's talk about how you can restore your system if everything goes wrong

### Use the Archlinux iso

Unfortunely void doesn't have much tools like arch, void is a light iso, i'm going to describe what you need to do, also the steps to follow to restore your system:

1. Boot to the live iso of Archlinux
2. Mount the `/dev/sdx2'` o `/dev/nvme0n1p2` on `/mnt`
3. Use nano to search info about your snapshot: `nano /mnt/@snapshots/*/info.xml` with `ctrl + x` you close the editor
4. Delete the `@` subvolume like a file: `rm -r /mnt/@` => This process take a while if you have many files on there
5. Finally restore the desire snapshot with btrfs: `btrfs subvolume snapshot /mnt/@snapshots/NUMOFSNAPSHOT/snapshot /mnt/@`
6. Reboot your system and you done..

## References

This guide is posible thanks to:

- **Void Linux Handbook**
    - [Void Handbook](https://docs.voidlinux.org/about/index.html).

- **Void Linux installation (XBPS method)**
    - [Guide by myTerminal](https://gist.github.com/myTerminal/82de59c83b2057868260d7185013e6d1).

- **Installation via Chroot**
    - [Guide Chroot](https://docs.voidlinux.org/installation/guides/chroot.html).

- **Snapper Wiki Archlinux**
   - [Snapper Wiki](https://wiki.archlinux.org/title/Snapper).

**Note**: All rights belong to their respective authors, this guide doesn't try to infringe copyright, this document is designed for educational proporses only, in the references section you have all the information about the sources that participated in the construction of this document with their respective licenses.

Oku &copy; 202X.
