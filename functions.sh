#!/bin/bash
PURPLE='\033[1;35m'
RED='\033[0;31m'
LRED='\033[1;31m'
NC='\033[0m' # No Color
CYAN='\033[0;36m'

setoption(){
echo "$1=$2" >> conffile.sh
}

setochrooption(){
echo "$1=$2" >> /my-arch/conffile.sh
}


#not used
line_sep(){
echo -ne "${PURPLE}-------------------------------------------------------------------------${NC}"
}

#not used
centerhead(){
echo -ne "${CYAN}$(printf "%*s\n" $(( ( $(echo $1 | wc -c ) + 80 ) / 2 )) "$1")${NC}\n"
}

echohead(){
echo -ne "${PURPLE}---------------------------------------------------------------------------------------------------${NC}\n"
echo -ne "$(printf "%*s\n" $(( ( $(echo $1 | wc -c ) + 80 ) / 2 )) "$1")\n"
echo -ne "${PURPLE}---------------------------------------------------------------------------------------------------${NC}\n"
}



logo () {
# This will be shown on every set as user is progressing
#font name; ANSI shadow
echo -ne "${NC}
${PURPLE}---------------------------------------------------------------------------------------------------${NC}
 █████╗ ██████╗  ██████╗██╗  ██╗      ██████╗ ██████╗ ███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║      ██╔══██╗██╔══██╗██╔════╝
███████║██████╔╝██║     ███████║${PURPLE}█████╗${NC}██║  ██║██████╔╝█████╗
██╔══██║██╔══██╗██║     ██╔══██║${PURPLE}╚════╝${NC}██║  ██║██╔══██╗██╔══╝
██║  ██║██║  ██║╚██████╗██║  ██║      ██████╔╝██║  ██║███████╗
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚══════╝
${PURPLE}---------------------------------------------------------------------------------------------------${NC}
"
}

select_option() {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "$2   $1 "; }
    print_selected()   { printf "${PURPLE}$2  $ESC[7m $1 $ESC[0;37m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    get_cursor_col()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${COL#*[}; }
    key_input()         {
                        local key
                        IFS= read -rsn1 key 2>/dev/null >&2
                        if [[ $key = ""      ]]; then echo enter; fi;
                        if [[ $key = $'\x20' ]]; then echo space; fi;
                        if [[ $key = "k" ]]; then echo up; fi;
                        if [[ $key = "j" ]]; then echo down; fi;
                        if [[ $key = "h" ]]; then echo left; fi;
                        if [[ $key = "l" ]]; then echo right; fi;
                        if [[ $key = "a" ]]; then echo all; fi;
                        if [[ $key = "n" ]]; then echo none; fi;
                        if [[ $key = $'\x1b' ]]; then
                            read -rsn2 key
                            if [[ $key = [A || $key = k ]]; then echo up;    fi;
                            if [[ $key = [B || $key = j ]]; then echo down;  fi;
                            if [[ $key = [C || $key = l ]]; then echo right;  fi;
                            if [[ $key = [D || $key = h ]]; then echo left;  fi;
                        fi
    }
    print_options_multicol() {
        # print options by overwriting the last lines
        local curr_col=$1
        local curr_row=$2
        local curr_idx=0

        local idx=0
        local row=0
        local col=0

        curr_idx=$(( $curr_col + $curr_row * $colmax ))

        for option in "${options[@]}"; do

            row=$(( $idx/$colmax ))
            col=$(( $idx - $row * $colmax ))

            cursor_to $(( $startrow + $row + 1)) $(( $offset * $col + 1))
            if [ $idx -eq $curr_idx ]; then
                print_selected "$option"
            else
                print_option "$option"
            fi
            ((idx++))
        done
    }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local return_value=$1
    local lastrow=`get_cursor_row`
    local lastcol=`get_cursor_col`
    local startrow=$(($lastrow - $#))
    local startcol=1
    local lines=$( tput lines )
    local cols=$( tput cols )
    local colmax=$2
    local offset=$(( $cols / $colmax ))

    local size=$4
    shift 4

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local active_row=0
    local active_col=0
    while true; do
        print_options_multicol $active_col $active_row
        # user key control
        case `key_input` in
            enter)  break;;
            up)     ((active_row--));
                    if [ $active_row -lt 0 ]; then active_row=0; fi;;
            down)   ((active_row++));
                    if [ $active_row -ge $(( ${#options[@]} / $colmax ))  ]; then active_row=$(( ${#options[@]} / $colmax )); fi;;
            left)     ((active_col=$active_col - 1));
                    if [ $active_col -lt 0 ]; then active_col=0; fi;;
            right)     ((active_col=$active_col + 1));
                    if [ $active_col -ge $colmax ]; then active_col=$(( $colmax - 1 )) ; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $(( $active_col + $active_row * $colmax ))
echo -ne "n\n"
}





set_timezone(){
echohead "Type the name of a big city in your timezone, with a capital letter in the beginning."
echo "If it's name has two words or more, use an underline _ ."
echo -ne "For example: Sydney, Manilla, New_York, Mexico_City \n:"
read cityname
echohead "Available matching timezones:"
timedatectl list-timezones | grep "$cityname"
echohead "now type the full name of your timezone (America/New_York for example):"
read seltz
echo "Set timezone is:$seltz"



echo "Set timezone is:$seltz" >> /my-arch/variables.log
ln -sf /usr/share/zoneinfo/$seltz /etc/localtime
hwclock --systohc
timedatectl set-ntp true

#for myself: previous versions of this are saved in functionslegacy.sh
}

set_locale(){
#too many options for english and spanish to make the options dialog
#the way i was doing it, and i dont know how to make every line turn into
# an option, I dont even know what "options" itself is, maybe a dictionary, idk
#anyways, typing is the only way here.
clear
logo
echohead "Type the two first letters indicating your language."
echo -ne "For example: en, for english, es for spanish \n:"
read langname
echo "Your langname is $langname"
echohead "Available languages:"
cat /etc/locale.gen | grep "$langname" | grep "UTF" | cut -c -7
#cat /etc/locale.gen | grep UTF | grep $langname
#echo -ne "${CYAN} Waiting 2 seconds... ${NC}"
#sleep 2
#echohead "ATTENTION!!!"

echo -ne "\n\n${CYAN}Now type the two letters indicating your country, with capital letters.${NC}
for example: GB, BR, PT.
:"
read countryname
localname=$(echo "$langname""_""$countryname")
echohead "Selected locale/language: ${CYAN}$localname${NC}. is it correct?"
options=("Yes" "No")
select_option $? 1 "${options[@]}"

case $? in
0) echo "ok";;
1) echo "type the correct then"; read localname;;
esac



echo "localname is $localname" >> /my-arch/variables.log
sleep 3

echo "localectl pre localconf is" >> other/installer.log
localectl >> other/installer.log
local_conf(){
echohead "Now for language configuration, type again the two letters indicating your country, like br for brazil and de for germany."
echo ":"
read br
#echohead "And now type what you loaded with loadkeys. If you ran loadkeys de-latin1, type de-latin1, for example."
#echo ":"
#read brabnt2
echo "making localectl stuff"
#localectl set-keymap $brabnt2
setochrooption br $br
localectl  set-x11-keymap $br
localectl set-keymap $br
#need to change confpacsudo to after aur, lightdm-gtk mentions and
#do localectl set-x11-keymap with sudo

}
local_conf
echo "the locale/language echoed was:$localname" >> other/installer.log
echo "for the localectl commands, brabnt2 is :$brabnt2 and the br is: $br" >> other/installer.log
localeservice(){

echo -ne "
[Unit]
Description=Configura automaticamente os temas diurnos

[Timer]
Unit=localedoer.service
OnActiveSec=2s
Persistent=true

[Install]
WantedBy=graphical.target
" > /etc/systemd/system/localedoer.timer

echo -ne "
#!/bin/bash
localectl set-x11-keymap $br
touch /lol
systemctl disable localedoer.timer
rm /etc/systemd/system/localedoer.timer
rm /etc/systemd/system/localedoer.service
rm /etc/systemd/system/script.sh
sleep 10
systemctl reboot
" > /etc/systemd/system/script.sh
chmod +x /etc/systemd/system/script.sh

echo -ne "
[Unit]
Description=roda o localectl

[Service]
Type=simple
ExecStart=/usr/bin/bash /etc/systemd/system/script.sh
User=root
" > /etc/systemd/system/localedoer.service

systemctl daemon-reload

systemctl enable localedoer.timer
}
localeservice


}


funsellocale(){
logo
echohead "Are you from the US?"
options=("Yes" "No")
select_option $? 1 "${options[@]}"
if [ "$?" = 1 ]; then
set_locale
cat /etc/locale.gen | grep "$localname" | grep "UTF" | cut -c 1-  >> /etc/locale.gen
locale-gen
echo "LANG=$localname.UTF-8" >> /etc/locale.conf
export "LANG=$localname.UTF-8"
clear
logo
echohead "Type your desired keyboard name"
echo -ne "If you ran a -loadkeys de-latin1- command before running this
script, type de-latin1. If you did a loadkeys br-abnt2, type br-abnt2. \n:"
read keyblayout
echo "Keyboard layout: $keyblayout"
echo "KEYMAP=$keyblayout" >> /etc/vconsole.conf


else
langname=en
countryname=US
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8
fi
}



confpacsudo(){
clear
logo
echohead "Do you want to enable sudo (test feature)?"
options=("Yes" "No" " ")
select_option $? 1 "${options[@]}"
if [ "$?" = 0 ]; then
pacman -S sudo --noconfirm

# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
usermod -aG wheel $youruser

else
echo "owok"
fi

#enabling parallel downloads
#sed -i -r 's/ParallellDownloads=true/ParallellDownloads/' /path/to/your/file
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed
}


swayinstall(){
echohead "This will erase your .profile and all of your sway/waybar configs. Proceed?"
options=("Yes" "No")
select_option $? 1 "${options[@]}"
if [ "$?" = 1 ]; then
    echo "Sorry, make partitions and come back later"

    exit 1
fi
echo -ne '
#!/bin/bash
cd
mkdir .config
git clone https://github.com/EndeavourOS-Community-Editions/sway.git
cd sway
cp -R .config/* ~/.config/
cp .profile ~/.profile
cp .gtkrc-2.0 ~/.gtkrc-2.0
chmod -R +x ~/.config/sway/scripts
chmod -R +x ~/.config/waybar/scripts
dbus-launch dconf load / < xed.dconf
' >> /home/$youruser/swayit.sh
chmod +x /home/$youruser/swayit.sh
runuser -u $youruser /home/$youruser/swayit.sh
cd /home/$youruser/sway
swaypacks="sway swayidle swaylock swaybg waybar lxappearance polkit-gnome thunar thunar-archive-plugin file-roller thunar-volman grim slurp awesome-terminal-fonts arc-icon-theme arc-gtk-theme gtk-engine-murrine mako wofi acpi bluez-utils network-manager-applet sysstat htop wayland-protocols xorg-xwayland egl-wayland gtk-layer-shell ttf-nerd-fonts-symbols xdg-desktop-portal-wlr brightnessctl pamixer wl-clipboard dex jq xed ttf-jetbrains-mono ttf-ubuntu-font-family xfce4-terminal lightdm-gtk-greeter lightdm-slick-greeter"
pacman -S --needed --noconfirm $swaypacks
systemctl enable lightdm
rm -rf /home/$youruser/sway /home/$youruser/swayit.sh

}









