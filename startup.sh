#!/usr/bin/env bash
#./installer.sh | tee other/installer.log
#cp conffile.txt other/conffile.txt


source functions.sh
source installer.sh
firststep | tee other/installer.log
#secondstep is called by postchroot, which is called by installer12
cp conffile.txt other/conffile.txt
cp other/installer.log installer.log
cd other
#python3 mailsender.py
#clear
logo

cp installer.log /mnt/my-arch/
cp variables.log /mnt/my-arch/
