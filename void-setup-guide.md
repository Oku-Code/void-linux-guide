# Void linux installation guide with btrfs file system, snapper and automatic snapshots and cleanup - By Oku

Hello and welcome, here i'm going to explain the basics about to setup, configure and install **void linux** an independent linux distribution, there are some tricks to get work with btrfs file system, in this case i recommend this guide if you want to have the following:

1. Btrfs file system with subvolumes
2. Create snapshots to maintain copies for your current system
3. Configure snapper, it's relative easy on this distribution

> **Note**: This distribution doesn't have **snapper_gui** you need to manage your snapshots manually.

## Table of contents

The document contains the following: 

1. [First steps](#first-steps)
    - [Preparing the iso file](#preparing-the-iso-file)
2. [Installing Void](#installing-void)
    - [Connecting to the network](#connecting-to-the-network)
    - [Updating xbps package manager](#updating-xbps-package-manager)
    - [Selecting the fastest mirror for faster downloads](#change-mirrors-for-faster-downloads)
    - [Partitioning your disk](#partitioning-your-disk)
    - [Installing base system](#installing-base-system)
3. [Void Chroot](#void-chroot)
4. [Configure snapper on void](#configure-snapper-on-void)
    - [How to configure snapper on Void Linux](#configure-snapper-on-void)
    - [How to rollback using snapper](#how-to-rollback-using-snapper)
    - [How to restore a snapshot using an Archlinux iso](#restoring-a-snapshot)
5. [Restoring a snapshot](#restoring-a-snapshot)
6. [References](#references)

> This guide is for intermediate and advance users of linux, don't be discourage for this message, if you want to learn
about linux, and know basic commands you can use this guide as well... 

## First steps

### Preparing the iso file:

So let's start first you need a USB and a Void Linux iso, where you can find it from the official website from void:

- Official Site: [VoidIso](https://voidlinux.org/download/)

> **Note**: this guide goes to _glibc_ version of void.

Now let's create the USB live iso, there are some many options to perform this task, most recommended programs are:

- **Windows**: [Rufus](https://rufus.ie/en/), [Balena etcher](https://www.balena.io/etcher/), [Ventoy](https://www.ventoy.net/en/download.html)
- **MacOS**: [Balena etcher](https://www.balena.io/etcher/), [Ventoy](https://www.ventoy.net/en/download.html)
- **Linux**: [Balena etcher](https://www.balena.io/etcher/), [Ventoy](https://www.ventoy.net/en/download.html) 

Boot into your iso file:

- In some computers you need to press **F11** or **Del** key to enter into the BIOS, in lenovo laptops use the **Novo button** to enter the boot menu, select the uefi memory and your are in.

## Installing Void

There are two ways to install void one is to type `void-installer` when you are loggin as a root user, this step is straight forward, the other method involves more effort from your part in order to have the configuration described at the beginning, but here i'm tell you how to do it using `chroot` procedure.

> _Tip_: Void is well documented by their developers, so check it out [here](https://docs.voidlinux.org/about/index.html) if you have some trouble with the installation process.

### Loading your keys

To change the keymaps of your keyboard to the following:

1. Search you keyboard layout: `ls /usr/kbd/keymaps/**/*.map.gz | grep less`
2. Setting up your keys: `loadkeys de-latin1` => This is for german keyboards, but choose your keyboard distribution instead 

### Connecting to the network:

The void xfce iso brings the posibity to connect into the network, so you can use it as well to connect to your network and procced with the next step, also if you have an wired connection you can skip this steps.

#### Connecting to a wifi network using wpa_supplicant

1. Using `wpa_supplicant` utility for wifi connections:
    - use `ip -a` to identify your network adapter in your case it be `wlslp0, wlan0` or something like that, in my case is `wlo1`
    - create a configuration file for your adapter with touch the command `touch /etc/wpa_supplicant/wpa_supplicant-wlo1.conf`
    - add the following lines in the apdapter config file using vi command `vi /etc/wpa_supplicant/wpa_supplicant-wlo1.conf`, with `:wq` you write and exit the editor:

```
ctrl_interface=DIR=/run/wpa_supplicant
update_config=1
```
2. Now time to append the information about the network using `wpa_passpharse` command:
    - `wpa_passphrase SSID PASSWORD >> /etc/wpa_supplicant/wpa_supplicant-wlo1.conf`
3. Connect to the network using the config file:
    - `wpa_supplicant -i -B wlo1 -c /etc/wpa_supplicant/wpa_supplicant-wlo1.conf`
4. Check the connection using `ping` command:
    - `ping https://docs.voidlinux.org`

### Change mirrors for faster downloads

It's important to have a good speed for downloads here i suggest two procedures in order to have a good download speeds:

#### Using the file localted in `/usr/share/xbps.d/00-repository.conf`

- Copy the file located in `/usr/share/xbps.d/00-repository.conf` on `/etc/xbps.d/`
- Use vi or other text editor and replace the default mirror for one nearest of your location, you can check the list of mirrors [here](https://docs.voidlinux.org/xbps/repositories/mirrors/index.html). 

#### Using the xmirrors utility

After you active your internet connection you can install with xbps the `xmirror` package and select your mirror from there

- `xmirror -l /usr/share/xmirror/mirrors.lst` => This launch the TUI utility and configure the mirror of your preference

### Updating xbps package manager:  

So, here we start updating the xbps package manager to this type the following commands:

- `xbps-install -Su xbps`: This syncronize the system and perform an update to xbps package manager.

> _Tip_: Here you can install the utilities you need, like and a text editor, `gptfdisk` utility and more

### Partitioning your disk:

Next is to use `cfdisk /dev/sdx` to create the partitions:

- You need create the `UEFI partition` and the `root partition`, with cfdisk command you can do it.
- Change the code to efi partition to `ef00`, and write the changes to the disk.
    > _Tip_: if you have a gpt label, instead install the `gptfdisk` package using the `xbps-install -Sy gptfdisk` command to use gdisk or cgdisk to perform operations on your disks.

> **Note**: if you dont know how your disk is assigned, use `lsblk` command to know it.

#### Creating the filesystems:

Its simple you need to use `mkfs.vat /dev/sdx1` for the Efi partition and `mkfs.btrfs /dev/sdx2` for the root partition.

> _Tip_: nvme partitions on linux are assigned as: `nvme0n1` for the disk and `nvme0n1p1` for partitions.

#### Creating the subvolumes for btrfs:

Next mount the large partition on `/mnt` and do the following:

- Create the subvolumes: we are using snapper for manage the snapshots, so you need to create this [scheme](https://wiki.archlinux.org/title/Snapper#Suggested_filesystem_layout).
    - **btrfs subvolumes**: `btrfs subvolume create /mnt/@`
    - Create the other subvolumes with the same command for: `@home`, `@var_log`, `@snapshots`.

> **Note**: @ symbol is described as the root subvolume where the base system will be installed, you can create more subvolumes as you wish, but for simplicity i'm keep it as the [scheme](https://wiki.archlinux.org/title/Snapper#Suggested_filesystem_layout) recommends.

#### Mounting the main partition with btrfs options:

Options depends of your disks:

- **HDD**: `mount -o compress=zstd,noatime,space_cache=v2,subvol=@ /dev/sdx2 /mnt`
- **SSD o NVME**: `mount -o compress=zstd,noatime,space_cache=v2,subvol=@,discard=async /dev/sdx2 /mnt`
> **Note**: You can change the compression algorithm in the mount options like `lzo`, also i recommend to leave an empty space for nvme or ssd devices

#### Making the mount directories:

Let's create the directories for the mount points:

- **For efi partition**: `mkdir -p /mnt/boot/efi`
- **For the subvolumes**: `mkdir -p /mnt/{home,.snapshots}`

#### Mounting the rest of the subvolumes:

And now lets mount the subvolumes:

- **Home**: `mount -o compress=zstd,noatime,space_cache=v2,subvol=@home /dev/sdx2 /mnt/home`
- **Snapshots**: `mount -o compress=zstd,noatime,space_cache=v2,subvol=@snapshots /dev/sdx2 /mnt/.snapshots`
- **Var_log**: `mount -o compress=zstd,noatime,space_cache=v2,subvol=@var_log /dev/sdx2 /var/log`

> **Note**: You can easily create a variable for the btrfs options like so: `BTRFS_OPTS=compress=zstd,noatime,space_cache=v2,autodefrag`, this variable will be used later.

#### Mount the efi partition

Finally the efi partition:

- **Efi**: `mount /dev/sdx1 /mnt/boot/efi`

> **Note**: if you attempt to install the system with a disk with gpt label on an MBR system remember to create a BIOS Boot Partition on your root of you disk
this allows to install the grub bootloader properly.

### Installing base system

Here on void its different, in Archlinux you have **pacstrap** command, but here you need to setup the following varibles before you procced with the installation:

1. Defining the main repo varible: `REPO=https://repo-default.voidlinux.org/current`

> **Note**: if you need to look up your nearest mirror in your country, can you find it on [mirrors](https://docs.voidlinux.org/xbps/repositories/mirrors/index.html) on the void handbook, change for the mirror of your preference.

2. Defining the archquitecture variable: `ARCH=x86_64`

3. Bootstraping the base-system: Now you need to install the system and the packages, here you specify what you want, this is an exmaple:

    - `XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system sudo vim git btrfs-progs base-devel efibootmgr mtools dosfstools grub-btrfs grub-x86_64-efi elogind dbus void-repo-nonfree` => pick your poison.

> **Note**: The packages `btrfs-progs grub-btrfs` are necesary for btrfs file system; At this point you can install the desktop enviroment of your choice, programs and more utilities, but it's better to do after you finish with the base installation and the `void-repo-nonfree` contains the `intel-ucode` package for Intel CPUS so installed to get better performace of your intel cpu, for more information go [here](#)

4. Entering chroot mode, you need mount the following files on to your system:

    - `for dir in dev proc sys run; do mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/$dir; done`

> Simplest way in my opinion to mount those files

5. Copy DNS config:

    - `cp /etc/resolv.conf /mnt/etc`

6. Finally chroot into your install:

    - `BTRFS_OPTS=$BTRFS_OPTS PS1='(chroot) # ' chroot /mnt/ /bin/bash`

> **Note:** Remember when i said this varible `BTRFS_OPTS` will be use it later, well when you are creating the fstab file this variable will make your live easier :)

### Void Chroot

This is a same process like arch with some exeptions, we review here now:

#### Generating the fstab file:

Here you need to be careful with the UUID of the disks, if you want to know the specific id use `blkid` command to see the UUIDs.

1. Store the UUIDS for the partitions we were created:

    - `UEFI_UUID=$(blkid -s UUID -o value /dev/sdx1)`
    - `ROOT_UUID=$(blkid -s UUID -o value /dev/sdx2)`

> Remember sdx or nvme0n1px or the letter that linux assign to your disk is your partition

2. Use the cat command to create the fstab file

```
cat << EOF > /etc/fstab
    UUID=$UEFI_UUID    /boot/efi     vfat     defaults,noatime     0 2
    UUID=$ROOT_UUID    /             btrfs    $BTRFS_OPTS,subvol=@ 0 1 
    UUID=$ROOT_UUID    /home         btrfs    $BTRFS_OPTS,subvol=@home 0 2 
    UUID=$ROOT_UUID    /.snapshots   btrfs    $BTRFS_OPTS,subvol=@snapshots 0 2 
    UUID=$ROOT_UUID    /var/log      btrfs    $BTRFS_OPTS,subvol=@var_log 0 2
    tmpfs              /tmp          tmpfs    defaults,nosuid,nodev     0 0 
EOF
```

> Why i don't know this before :(, also use the `cat` command to check if all the variables are correct and place it.

#### Configure timezone:

- `ln -sf /usr/share/zoneinfo/America/Bogota /etc/localtime`: this set the timezone of your region

> _Tip_: You can use the following commands to search your timezone and setting up: `ls /usr/share/zoneinfo` to list your region and `ls /usr/share/zoneinfo/America` list your city, _hopefully your find it_

#### Additional config:

- `vim /etc/rc.conf`: here define the locales, fonts and also the vconsole keymaps

#### Generating the locales:

- `vim /etc/default/libc-locales`: Uncomment your location
- `xbps-reconfigure -f glibc-locales`: Generate locales according with your choice


#### Synchronize the hardware clock with the system clock

- `hwclock --systohc`: this sychronize the system clock

#### Setting hostname:

- `vim /etc/hostname`: Define your machine name.

#### Configuring the network:

- The configuration on this file is the same like in Archlinux, you can find it [here](https://wiki.archlinux.org/title/Installation_guide#Network_configuration).

```
127.0.0.1   localhost
::1         localhost
127.0.1.1   hostname.localdomain    hostname
```

#### Enabling others serivces

- Use the following command: `ln -srf /etc/sv/{dbus,elogind} /var/service`

#### Enabling network services

- Create the respective symbolic links of the services: `ln -srf /etc/sv/{dhcpd,dhcpd-eth0} /var/service`

    > _Tip_: use the `sv` command to check the services are runing when you enter to the system for first time, like this: `sudo sv status /var/service/*`

> **Note**: When you enter on system for first time, you don't have internet connection, in order to connect to the internet again go and do
the step 5 and 6 in the [Connecting to the network](#connecting-to-the-network) section, on the other hand if you installed the `NetworkManager` package
you can use the `nmtui` utility and select the wireless network, if you have an internet cable the network is detected automatically.


#### Create a root password:

- Use `passwd` to create a root password

#### Create a user:

- Use `useradd -mG wheel NAMEOFUSER`
- Use `paswd NAMEOFUSER` to create a new password
- Add the user to the wheel group, `EDITOR=vim visudo` and uncomment `%wheel ALL= (ALL) ALL`

#### Installing the bootloader:

- `grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void Linux"`, type this command to install grub.
-  create the grub config file: `grub-makeconfig -o /boot/grub/grub.cfg`.

> **Note:** for MBR partitions, or an gpt label in a MBR system execute the following: `grub-install --target=i386-pc /dev/sdx`, notice i'm selecting the volume not the partition, is a common error

#### Update initramfs

- Finally generate the new installation: `xbps-reconfigure -fa`

- From here you need to exit from the chroot mode and a umount all the partitions, 

    - `umount -R /mnt`
    - `shutdown -r now`

#### **And congratulations you made it void is installed with btrfs file system**

## Configure snapper on void

In order to use snapper on Void you need to configure it first, so let's do it:

1. Update your system:

    - `sudo xbps-install -Su`

2. Install snapper:

    - `sudo xbps-install -S snapper`

3. Enable snapper service and grub-btrfs service:

    - `ln -srf /etc/sv/{snapperd,grub-btrfs} /var/service`

> **Note**: grub-btrfs show the snapshots in the grub bootloader and allows you enter on your created snapshots from snapper.

4. Umount the /.snapshots directory:

    - `sudo umount /.snapshots/`

5. Delete the ./snapshots directory:

    - `sudo rm -r /.snapshots`

6. Create the configuration file for snapper, add your current user and configure your snapshots limits schedule:

   - `sudo snapper -c root create-config /` => This create the config file for snapper called _root_, you can choose the name whatever you like
   - `sudo vim /etc/snapper/configs/root` => Change __ALLOW_USERS=""__ for __ALLOW_USERS="NAMEOFUSER"__, this is for make our user own of the snapshots and perform operations on it

> If you need to know how to configure your limit schedule go [here](https://wiki.archlinux.org/title/Snapper#Set_snapshot_limits)

7. Delete the /.snapshots subvolume:

    - `sudo btrfs subvolume delete /.snapshots`

8. Create a new /.snapshots directory : 

    - `sudo mkdir /.snapshots`

9. Mount the new directory /.snapshots on @snapshots subvolume: 

    - `sudo mount -a`

10. Change permisions for the folder and the user access:

    - `sudo chmod a+rx /.snapshots` => Change the permission of the folder
    - `sudo chown :username /.snapshots` => Change the permission of the user

11. Verify the creation of the snapshots:

    - `snapper -c root list` => list the snapshots presents on the snapper config file **in this case shows only current, that means the snapshot is running**.
    - `sudo snapper -c root create -c timeline -d "Test snapshot"` => Create a test snapshot
    - `snapper -c root list or snapper ls` => Listed again with the last created snapshot
    - `sudo snapper delete 1` => And delete the snapshot created
    - If you want more information about the snapper commands you can go to [Snapper Wiki](https://wiki.archlinux.org/title/Snapper#Manual_snapshots).

    > **Note**: These snapshots are read_only, that means you can read it, but not make changes, to make it writable do the folowing:

    - See the properties of the selected snapshot: `btrfs property list /.snapshots/1/snapshot` => Here we select the number 1, you can select any you want
    - Make it writable: `btrfs property set -ts /.snapshots/1/snapshot ro false`
    - Boot in the selected snapshot from grub bootloader and create a file inside of the snapshot 

12. Automating the process using cronie:

    - Install cronie with xbps: `sudo xbps-install -Sy cronie`
    - Enable the service with the symbolic link: `ln -s /etc/sv/cronie /var/service` and `ln -s /etc/sv/crond /var/service`
    - And you done, create an snapshot with the procedure above and check in the grub menu at startup if there's snapshots of your sistem present in the bootloader

## How to rollback using snapper

You can rollback a snapshot if you want to test something and goes weird

1. List all the snapshots: `sudo snapper ls`
2. Create a snapshot of your system: `sudo snapper -c root create -c timeline -d "System testing"` => Define the name you want for you snapshot

> **Tip**: Here you can do the things you need to do and think you compromise your system in a dangerous way -> DO IT BY YOUR OWN RISK

3. Rollback a snapshot: `sudo snapper rollback NUMOFSNAPSHOT` => NUMOFSNAPSHOT is the snapshot selected, you'll get an error

```
Cannot detect ambit since default subvolume is unknown.
This can happen if the system was not set up for rollback.
The ambit can be specified manually using the --ambit option.
```
4. Setup the ambit option for snapper: `sudo snapper --ambit classic rollback NUMOFSNAPSHOT` => now you are able to rollback your snapshot

> **Note**: This configuration doesn't have the capability to do snapshots when you are updating or installing a package, so the _pre_ and _post_ snapshots aren't available,
the rollback option can supply this necesity, but this distribution doesn't have a system hook like Archlinux or a package to manage the changes that made the package manager like 
dnf on Fedora, so keep that in mind...
 
## Restoring a snapshot 

Now let's talk about how you can restore your system if everything goes wrong

### Use the Archlinux iso

Unfortunely void doesn't have much tools preinstalled like arch, void is a light iso, you can install all the tools do you need in the live iso if you want,
but i'm going to describe what you need to do, also the steps to follow to restore your system using the Archlinux iso:

1. Boot to the live iso of Archlinux
2. Mount the root partition `/dev/sdx2'` or `/dev/nvme0n1p2` on `/mnt`
3. Use nano to search info about your snapshot: `nano /mnt/@snapshots/*/info.xml` with `ctrl + x` you close the editor
4. Delete the `@` subvolume like a file: `rm -r /mnt/@` => This process take a while if you have many files on there
5. Finally restore the desire snapshot with btrfs: `btrfs subvolume snapshot /mnt/@snapshots/NUMOFSNAPSHOT/snapshot /mnt/@`
6. Reboot your system and you done..

## References

This guide is posible thanks to this resources:

- **Void Linux Handbook**
    - [Void Handbook](https://docs.voidlinux.org/about/index.html).

- **Grabiel Sanches's Handbook**
    - [Guide by Grabiel Sanches](https://help.gsr.dev/void-linux/ch01-00-introduction.html)

- **Installation via Chroot**
    - [Guide Chroot](https://docs.voidlinux.org/installation/guides/chroot.html).

- **Snapper Wiki Archlinux**
   - [Snapper Wiki](https://wiki.archlinux.org/title/Snapper).

- **How to connect to the network using wpa_supplicant on void linux by Luca**
    - [Blogpost by Luca](https://lucacorbucci.medium.com/how-to-connect-to-wi-fi-from-terminal-using-wpa-supplicant-on-void-linux-9c9fe6ca5403)

- **eflinux Youtube Channel**
    - [eflinux channel](https://www.youtube.com/@eflinux)

> All rights belong to their respective authors, this guide doesn't try to infringe copyright, this document is designed for educational proporses only, in the references section you have all the information about the sources that participated in the construction of this document with their respective owners and licenses.

OkuCode &copy; 2023.
