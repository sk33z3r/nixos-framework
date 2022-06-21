{ config, pkgs, ... }:

{

  # Extra packages
  environment.systemPackages = with pkgs; [
    ipfs ipget
  ];

  # Enable the service
  services.ipfs = {
    enable = true;
    gatewayAddress = "/ip4/0.0.0.0/tcp/9393";
    autoMigrate = false;
  };

  # Extra aliases
  programs.fish.shellAliases = {
    ipfsh = "/etc/ipfs-helper.sh";
  };

  # Scripts
  environment.etc = {
    "ipfs-helper.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        upload="./upload"
        mkdir -p $upload
        case $1 in
            dir)
                if [[ ! -z $2 ]]; then
                    dir=$2
                    cid=$(ipfs add -Q -r $dir)
                    ipfs pin add $cid
                    rm -r $dir
                else
                    echo "Error: forgot to specify a directory path!"
                    exit 1
                fi
            ;;
            cid)
                if [[ ! -z $2 ]]; then
                    cid=$2
                    ipfs pin add --progress=true $cid
                else
                    echo "Error: forgot to specify a CID!"
                    exit 1
                fi
            ;;
            stats) ipfs stats repo -H;;
            pins) ipfs pin ls -t recursive;;
            add)
                for f in $(ls $upload); do
                    echo "Adding $f..."
                    cid=$(ipfs add -Q $upload/$f)
                    ipfs pin add $cid
                    rm $upload/$f
                done
            ;;
            restart)
                systemctl restart ipfs.service
                chmod -R 755 /var/lib/ipfs
            ;;
            *)
                echo "Usage: $0 [dir|cid|stats|pins|add|restart] {directory|cid}"
            ;;
        esac
      '';
    };
  };

}