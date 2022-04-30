#!/usr/bin/env bash
#!/usr/bin/env bash
source functions.sh
firststep(){
#the seconds step is invoked by postchroot.sh after... chrooting.


clear
logo
echo -ne "
------------------------------------------------------------------------
"

#########                   CONFIGURING PARTITIONS          ###########
clear
logo
lsblk -o NAME,SIZE,FSTYPE
echo -ne "${NC}\nWhat drive do you wanna use? type sda, for example  \n:"
read sda
setoption sda $sda
echo -e "\n\n\n"
centerhead "You have chosen $sda."

echohead "Do you have partitions?"
options=("Yes" "No")
select_option $? 1 "${options[@]}"
if [ "$?" = 1 ]; then
    echo "Sorry, make partitions and come back later"
  
    exit 1
fi




#######          SETTING EFI                 ######
echohead "Select what partition to use as /boot. The script doesnt work with bios, for real"

lsblk -o NAME,SIZE,FSTYPE | grep "$sda"



options=( "Available Partitions for EFI:" "$(echo $sda)1" "$(echo $sda)2" "$(echo $sda)3" "$(echo $sda)4" "$(echo $sda)5" "$(echo $sda)6" "$(echo $sda)7" "$(echo $sda)8" "$(echo $sda)9" "$(echo $sda)10")
select_option $? 1 "${options[@]}"

#actualpartnum=$(echo "$(($?+1))")
actualpartnum=$?
echo "$sda$actualpartnum" >> conffile.txt
echo "Your efi partition is $sda$actualpartnum"
#selefi="$(head -2 conffile.txt | tail -1)"
#works, but its messy, sed is better for reading the conf file;
selefi="$(sed -n 1p conffile.txt)"
setoption selefi $selefi
#selefi is the efi partition, first line on the conffile
centerhead "You selected $selefi as /boot"



#####           SETTING SLASH       #########
echohead "Select what partition to use as /"
lsblk -o NAME,SIZE,FSTYPE | grep "$sda"

options=( "Available Partitions for SLASH:" "$(echo $sda)1" "$(echo $sda)2" "$(echo $sda)3" "$(echo $sda)4" "$(echo $sda)5" "$(echo $sda)6" "$(echo $sda)7" "$(echo $sda)8" "$(echo $sda)9" "$(echo $sda)10")
select_option $? 1 "${options[@]}"

actualpartnum=$?
echo "$sda$actualpartnum" >> conffile.txt
echo "you choose $sda$actualpartnum"
selslash="$(sed -n 2p conffile.txt)"
#selslash="$(head -1 conffile.txt)"
#selpart is the selected part, the first line on the conff file
centerhead "You selected $selslash as /"
setoption selslash $selslash

echo -ne "
                  you have selected the following disk config:
  disk in use:/dev/$sda
        slash: /dev/$selslash
        /boot: /dev/selefi
"
lsblk -o PATH,NAME,SIZE,FSTYPE | grep "$sda"
options=("Proceed?" "Yes" "No")
select_option $? 1 "${options[@]}"
case $? in
0) echo "why did you select this lol"; exit 1;;
1) echo owok;;
2) lsblk; exit 1;;
esac




###############           MAKING FILESYSTEMS          #######
logo
echohead "Making Filesystem for EFI part ($selefi)"

echohead "Do you want to format your boot partition? (no if you want to dualboot)"
options=("Yes" "no")
select_option $? 1 "${options[@]}"

case $? in
0) mkfs.fat -F32 /dev/$selefi;;
1) echo "owok";;
esac
setoption erasefi $?
clear
logo

#####           CHOOSING FILESYSTEMS        ######
clear
logo
echohead "what filesystem do you want to use on slash?"

options=("Available options for filesystem:" "ext4" "btrfs -doesnt work" "xfs -doesnt work")
select_option $? 1 "${options[@]}"
case $? in
0) echo "why did you select this lol"; exit 1;;
1) selFS="ext4";;
2) selFS="btrfs";;
3) selFS="xfs";;
esac
centerhead "Selected $selFS"
setoption selFS $selFS


if [ $selFS = ext4 ]; then
mkfs.ext4 -F /dev/$selslash
else
mkfs.$selFS -f /dev/$selslash
fi
sleep 3

setoption selFS "$selFS"

#####       doing mirror stuff       #####
funcmirror(){
logo
echohead "Preparing for mirror configuration"
pacman -S reflector --noconfirm

clear
logo
echohead "Preparing for mirror configuration"
echo -ne "What country do you want to look for mirrors in?
typing US,Germany will search for mirrors in both countries "
echo -ne ":"
read mircountry
centerhead "You have selected $mircountry."
echohead "Getting the best mirrors"
reflector --country $mircountry --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
}
funcmirror


######     mounting slash and efi        ######
clear
logo
echohead "Mounting future slash and efi on /mnt"
#mount /dev/$selslash /mnt

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

#####            PACSTRAP BABY        #####
clear
logo
echohead "Installing base and kernel packages with pacstrap"
if [ $selFS = "btrfs" ]; then
pacstrap /mnt base linux-zen linux-firmware btrfs-progs
else 
pacstrap /mnt base linux-zen linux-firmware
fi
#####           FSTAB           ####


func_selhome(){
logo
lsblk -o NAME,PATH,SIZE,FSTYPE
echohead "type your drive name, sda for example"
read sda
lsblk -o NAME,PATH,SIZE,FSTYPE | grep "$sda"
options=( "Available Partitions for HOME:" "$(echo $sda)1" "$(echo $sda)2" "$(echo $sda)3" "$(echo $sda)4" "$(echo $sda)5" "$(echo $sda)6" "$(echo $sda)7" "$(echo $sda)8" "$(echo $sda)9" "$(echo $sda)10")
select_option $? 1 "${options[@]}"

#actualpartnum=$(echo "$(($?+1))")
actualpartnum=$?
echo "$sda$actualpartnum" >> conffile.txt
echo "Your home partition is $sda$actualpartnum"
#selefi="$(head -2 conffile.txt | tail -1)"
#works, but its messy, sed is better for reading the conf file;
selhome="$(sed -n 3p conffile.txt)"
#selefi is the efi partition, first line on the conffile
centerhead "You selected $selhome as /home"
sleep 1
mkdir /mnt/home
mount /dev/$selhome /mnt/home
setoption selhome $selhome
}

echohead "Do you want to mount a separate home part that wont be formatted?"
options=("Yes" "no")
select_option $? 1 "${options[@]}"

case $? in
0) func_selhome;;
1) echo "owok";;
esac


clear
logo
lsblk
centerhead "Setting the fstab and chrooting"
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
sleep 2
echohead "Chrooting soon"

#cd /mnt
#git clone https://github.com/GuaximFsg/my-arch
#cp /root/my-arch/conffile.sh /mnt/my-arch/conffile.sh
#cd
#sleep 5
#cp /root/my-arch/yourconf.sh /mnt/my-arch

cp -r /root/my-arch /mnt
arch-chroot /mnt my-arch/postchroot.sh

}










secondstep(){
### chrooting
#source arch-dre/functions.sh



#####           TIMEZONE, LOCALE AND SIMILAR        #####
cd /
source arch-dre/functions.sh
clear
logo
set_timezone
echo "the command ran for timezone setting was: timedatectl set-timezone $seltz" >> variables.log


funsellocale

#####           HOSTNAME            #####3
clear
logo
echohead "Configuring hostname, hosts file and networking"
echo -ne "Type your hostname \n:"
read hostename
echo $hostename >> /etc/hostname
echo "
127.0.0.1	localhost
::1		localhost
127.0.1.1	$hostename
" >> /etc/hosts

######          PASSWD          #####
clear
logo
echohead "Configure the host password"
passwd

#####              GRUB INSTALL AND CONFIG      #######
clear
logo



if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
  echohead "Installing GRUB -twice-"
pacman -S grub --noconfirm
  grub-install --target=i386-pc /dev/$sda
  grub-mkconfig -o /boot/grub/grub.cfg
  else
  echohead "Installing GRUB -twice-"
pacman -S grub efibootmgr --noconfirm
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUBOWO
grub-mkconfig -o /boot/grub/grub.cfg
sleep 2
fi


#####           INSTALLING AND SOFTWARE
echohead "Please pay attention to any errors in the previous step"
logo
echohead "Do you want to install mesa drivers? (for amd and intel graphics)"
options=("Yes" "No")
select_option $? 1 "${options[@]}"

case $? in
0) pacman -S mesa --noconfirm --needed;;
1) echo "owok";;
esac
echohead "Installing networkmanager"
pacman -S networkmanager git  --needed --noconfirm
systemctl enable NetworkManager

#making users
clear
logo
echohead "Type your username"
read youruser
useradd -m "$youruser"
passwd "$youruser"
setoption youruser $youruser

#####       setting sudo and pacman parallel downloads



##### function to set up the aur helper
funselaur(){
clear
logo

funcitaur(){
    pacman -S --needed --noconfirm base-devel
    mkdir /yay
    chown -R $youruser /yay
    runuser -u $youruser /arch-dre/user.sh
    pacman -U /yay/yay-bin/yay-b*
    rm -r /yay
}

echohead "Do you want to install yay(bin) as your aur helper?"
options=("yay" "no" " ")
select_option $? 1 "${options[@]}"

case $? in
0) aur="yay"; funcitaur;;
1) echo "owok";;
esac
}
#funselaur needs to be run cuz it asks you if you want to install yay
funselaur
#funselaur function contain everything related to the aur, dont know why i did it this way
#####        installing desktop environments

setde(){
clear
logo
echohead "what de do you want to install?"
options=("xfce4" "KDE (best de)" "gnome (bad)" "EOS-sway" "none")
select_option $? 1 "${options[@]}"

case $? in
0) pacman -S --noconfirm xfce4 thunar xfce4-terminal lightdm-gtk-greeter lightdm lightdm-slick-greeter; systemctl enable lightdm;;
1) pacman -S plasma dolphin kate konsole sddm --noconfirm; systemctl enable sddm;;
2) pacman -S gnome gdm nautilus gnome-terminal --noconfirm ; systemctl enable gdm;;
3) swayinstall;;
4) echo owok;;
esac
}
setde

#######         DOING SUDO STUFF
confpacsudo
clear
logo

##### USER SOFTWARE
clear
logo
echohead "Type all of the packages you want to install, separated by one space. eg: telegram-desktop firefox libreoffice-fresh "
echo ":"
read usersoftware
pacman -S --noconfirm --needed $usersoftware

###
echohead "Do you want to install all the bloat that me, andre, the creator of this shitty script, usually installs?"
options=("Yes" "No")
select_option $? 1 "${options[@]}"
case $? in
0) pacman -S --needed bluez pulseaudio-bluetooth bluetooth git ffmpegthumb firefox telegram-desktop zsh;;
1) echo "owok";;
esac

### bye
clear
logo
echohead "It was a pleasure to install your system!"
sleep 2
exit
}
