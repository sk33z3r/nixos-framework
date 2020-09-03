#!/usr/bin/env bash

checkRoot() {
    if [[ $(whoami) != "root" ]]; then
        echo "Run as root!"
        exit 1
    fi
}

dir="$PWD"

gitPull() {
    git pull
    git submodule update
    if ! cmp $dir/git.sh $dir/framework/.template/git.sh; then
        cp $dir/framework/.template/git.sh $dir/git.sh
        echo "The helper script changed during the update, run it again!"
        exit 1
    fi
}

usage() {
cat <<EOF

Usage: $0 [argument]

                        | no argument runs git pull
  -s, --switch          | pulls from git, switches config
  -u, --upgrade         | pulls from git, forces package upgrades while switching
  -f, --framework       | pulls and commits the latest framework from master
  -l, --link [name.nix] | links the configuration.nix file
  -h, --help            | this help message

EOF
}

case $1 in
    -s|--switch)
        checkRoot
        gitPull
        ./framework/nix.sh switch
        chown -R root:root /var/spool/nginx
        chmod -R 777 /var/spool/nginx
        systemctl restart nginx.service
        systemctl restart syncthing.service
    ;;
    -u|--upgrade)
        checkRoot
        gitPull
        ./framework/nix.sh upgrade
        chown -R root:root /var/spool/nginx
        chmod -R 777 /var/spool/nginx
        systemctl restart nginx.service
        systemctl restart syncthing.service
    ;;
    -f|--framework)
        cd $dir/framework
        oldCommit=$(git rev-parse --short HEAD)
        git pull origin master
        newCommit=$(git rev-parse --short HEAD)
        cd $dir
        message="chore: update framework commit $oldCommit..$newCommit"
        git add framework
        if ! cmp $dir/git.sh $dir/framework/.template/git.sh; then
            cp $dir/framework/.template/git.sh $dir/git.sh
            git add git.sh
            message="$message, update git.sh"
        fi
        git commit -m "$message"
        case $2 in
            -p|--push) git push;;
            *) echo "New framework committed, but changes were not pushed.";;
        esac
    ;;
    -l|--link)
        checkRoot
        FILENAME=$2
        while [[ $(echo $FILENAME | awk -F'.' '{print $2}') != "nix" ]] || [[ ! -f $dir/$FILENAME ]]; do read -p "ERROR: Invalid filename, try again: " FILENAME; done
        if [[ -L /etc/nixos/configuration.nix ]]; then
            ls -l /etc/nixos/configuration.nix
            echo "ERROR: Config is already a symlink. Create a new one any way? (y/N) " ans
            case $ans in
                y|yes|Y|YES|Yes) rm -f /etc/nixos/configuration.nix;;
                *) echo "Leaving the file alone."; exit 0;;
            esac
        else
            mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.bak
            echo "Backed up old config to /etc/nixos/configuration.nix.bak"
        fi
        ln -s $dir/$FILENAME /etc/nixos/configuration.nix
        echo "New config linked"
        ls -l /etc/nixos/configuration.nix
    ;;
    -h|--help) usage;;
    *) gitPull;;
esac
