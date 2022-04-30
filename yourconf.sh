#!/usr/bin/env bash
source ../functions.sh


# this is your region or country, for example, America, Australia, Europe. Use underslash and capital letters.
# will be used to set locales
region_country="America"
# your city, like New_York
cityy="Sao_Paulo"

# the keyboard you loaded with loadkeys earlier
keyblayt="br-abnt2"
# x11-keymap to be set. br for brazil, for example. they can be listed
# with th command: localectl list-x11-keymap-layouts
x11keymap="br"
#LANG variable. pt_BR means brazilian portuguese
languagee="pt_BR.UTF-8 UTF-8"

# host name and software to be installed, including desktop environment and drivers
hostename="endeowo"
software="mesa plasma git dolphin kate konsole"
#dm you need to enable. gdm for gnome for example.
#if you want lightdm, dont forget to install lightdm and lightm-slick-greeter, otherwise it wont work
dm="sddm"


#if you want sudo, leave sudo=1, if dont, sudo=0, same applies to aur
sudo=1
installyaybin=1

#username
youruser=Guaxim







#locale and keyboard and language
ln -sf /usr/share/zoneinfo/$region_country/$cityy /etc/localtime
hwclock --systohc
locale-gen
echo -ne "
en_US.UTF-8 UTF-8
$languagee
" >> /etc/locale.gen
echo "$languagee" >> /etc/locale.conf
localectl set-keymap $keyblayt
localectl set-x11-keymap $x11keymap

#HOSTNAME
echo $hostename >> /etc/hostname
echo "
127.0.0.1	localhost
::1		localhost
127.0.1.1	$hostename
" >> /etc/hosts


#   password
passwd


# INSTALLING GRUB  FOR UEFI


clear
logo
echohead "Installing GRUB -twice-"
pacman -S grub efibootmgr --noconfirm

pacman -S grub efibootmgr --noconfirm
echohead "Installing grub"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
sleep 2



pacman -S $software --noconfirm --needed
systemctl enable NetworkManager
systemctl enable $dm

useradd -m "$youruser"
passwd "$youruser"




if [ $installyaybin = 1 ]; then
  sudo pacman -S --needed --noconfirm base-devel
  mkdir /yay
  chown -R $youruser /yay
  runuser -u $youruser /arch-dre/user.sh
  pacman -U --noconfirm/yay/yay-bin/yay-bin*
  rm -r /yay
fi

if [ $sudo = 1 ]; then
pacman -S sudo --noconfirm
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
usermod -aG wheel $youruser
fi



if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
  grub-install --target=i386-pc /dev/$sda
  grub-mkconfig -o /boot/grub/grub.cfg
  else
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
sleep 2
fi

