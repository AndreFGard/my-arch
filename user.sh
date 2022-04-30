#!/usr/bin/env bash
placer=$PWD
pawd=$placer
cd $pawd
cd /yay/
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg
cd $pawd

