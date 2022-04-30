#!/bin/bash
source functions.sh

if [ $selFS = "btrfs" ]; then
mount /dev/$selslash /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@var
btrfs su cr /mnt/@opt
btrfs su cr /mnt/@tmp
btrfs su cr /mnt/@.snapshots
umount /mnt



mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@ /dev/$selslash /mnt
# You need to manually create folder to mount the other subvolumes at
mkdir /mnt/{boot,home,var,opt,tmp,.snapshots}

mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@opt /dev/$selslash /mnt/opt

mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@tmp /dev/$selslash /mnt/tmp

mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@.snapshots /dev/$selslash /mnt/.snapshots

mount -o subvol=@var /dev/$selslash /mnt/var
else 
mount /dev/$selslash /mnt
fi

#noatime,compress=zstd,commit=120 are the chris titus
#echo "THIS IS YOUR FUCKING  / without any spaces FUCK:$selslash"
#i was mad when i wrote this sorry
echo "mounted slash"
lsblk | grep "$selslash"
sleep 2
mkdir /mnt/boot
mount /dev/$selefi /mnt/boot
lsblk
echo "mounted efi to $(lsblk | grep $selefi)"
sleep 2