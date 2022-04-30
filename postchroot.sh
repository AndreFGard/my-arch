#!/usr/bin/env bash
# source /my-arch/installer.sh
# source /my-arch/functions.sh
if [ -f /root/my-arch/startup.sh ]; then # check if file exists
    echo -e "conffile.txt already exists, deleting in 2... \n"
    #source /root/my-arch/installer.sh
    source /root/my-arch/functions.sh
    source /root/my-arch/conffile.sh
else
    source /my-arch/installer.sh
    source /my-arch/functions.sh
    source /my-arch/conffile.sh

fi
source /my-arch/functions.sh
source functions.sh

secondstep | tee other/installer-secondstep.log
echohead "Chroot successful"


