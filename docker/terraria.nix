{ config, pkgs, ... }:

let

  SERVICE = "terraria";
  DATA_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}
    '';
    deps = [];
  };

  # Extra aliases
  programs.fish.shellAliases = {
    "${SERVICE}" = "/etc/${SERVICE}.sh";
  };

  # Configs and scripts
  environment.etc = {
    "${SERVICE}.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        image="beardedio/terraria:vanilla-latest"
        case $1 in
          start)
            if [[ -z $2 ]]; then
              cd ${DATA_DIR}
              echo "Worlds found:"
              ls -1 *.wld
              echo
              read -p "Start which world? " WORLD
              while [[ $(echo $WORLD | awk -F'.' '{print $2}') != "wld" ]]; do read -p "Error: Enter the whole filename (including .wld)! Try again: " WORLD; done
            else
              WORLD=$2
            fi
            if [[ -f ${DATA_DIR}/$WORLD ]]; then
              cp /etc/${SERVICE}.txt ${DATA_DIR}/serverconfig.txt
              docker run -dit -p 10000:7777 \
                -v ${DATA_DIR}:/config \
                --name="${SERVICE}" -e world=$WORLD \
                --restart always $image
            else
              echo "Error: World not found. Was it in the list?"
              exit 1
            fi
          ;;
          stop) docker stop ${SERVICE}; docker rm ${SERVICE};;
          restart) docker restart ${SERVICE};;
          console)
            echo -e "Attached to ${SERVICE}\nCTRL+P / CTRL+Q to detach >>\n"
            docker logs --tail 25 ${SERVICE}
            docker attach ${SERVICE}
          ;;
          update) docker pull $image;;
          *) echo "E: Invalid Command"; exit 1;;
        esac
      '';
    };
    "${SERVICE}.txt" = {
      text = ''
        maxplayers=8
        port=7777
        password=diarrhea@boiz
        motd=It's a damned Terraria.
        worldpath=/config
        banlist=/config/banlist.txt
        language=en-US
        upnp=1
        priority=1
      '';
    };
  };

}