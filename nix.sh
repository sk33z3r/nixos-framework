#!/usr/bin/env bash

if [[ $(whoami) != "root" ]]; then
    echo "Error: Must run as root!"
    exit 1
fi

# Setup environment
dir=/root/nixops
cd $dir

case $1 in
    switch) nixos-rebuild switch;;
    upgrade) nixos-rebuild switch --upgrade;;
    edit) nano /etc/nixos/configuration.nix;;
    --link)
        if [[ -z $2 ]]; then
            echo "Error: Missing machine name argument"
            exit 1
        fi
        name=$2
        rm /etc/nixos/configuration.nix; ln -s $dir/$name.nix /etc/nixos/configuration.nix
    ;;
    --dist-upgrade)
        if [[ -z $2 ]]; then
            echo "Error: Missing version argument"
            exit 1
        fi
        ver=$2
        nix-channel --add https://nixos.org/channels/nixos-$ver nixos
        sudo nixos-rebuild switch --upgrade
    ;;
    *) echo -e "\nUsage: $0 [switch|upgrade|edit]\n       $0 --link <name>\n       $0 --dist-upgrade <version>\n"; exit 1;;
esac