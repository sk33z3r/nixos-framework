{ DOMAIN, MUSIC_DIR }:

let

  SERVICE = "funkwhale";
  IP4 = "60";
  DATA_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}
      mkdir -p ${MUSIC_DIR}
      chown -R 1000:100 ${MUSIC_DIR}
    '';
    deps = [];
  };

  # Generate common configs and scripts
  imports = [
    ../nixos/packages/media.nix
    ( import ./common.nix { SERVICE = "${SERVICE}"; } )
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "https://172.100.0.${IP4}/";
      HOST_HEADER = "$host";
    } )
  ];

  # Define import script alias
  programs.fish.shellAliases = {
    "${SERVICE}-import" = "/etc/${SERVICE}-import.sh";
  };

  # Define docker-compose.yml and import script
  environment.etc = {
    "${SERVICE}-import.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # import library files
        read -p "Enter your Library ID: " LIBRARY_ID
        if [[ -z $LIBRARY_ID ]]; then echo "ID can't be empty!"; exit 1; fi
        docker exec -it ${SERVICE} manage import_files $LIBRARY_ID "/music/*/*/*.mp3" --in-place --async
        docker exec -it ${SERVICE} manage import_files $LIBRARY_ID "/music/*/*/*.ogg" --in-place --async
        docker exec -it ${SERVICE} manage import_files $LIBRARY_ID "/music/*/*/*.flac" --in-place --async
      '';
    };
    "${SERVICE}.compose" = {
      text = ''
        version: '3.7'
        services:
          ${SERVICE}:
            image: thetarkus/funkwhale:latest
            container_name: ${SERVICE}
            environment:
              - PUID=1000
              - PGID=100
              - FUNKWHALE_HOSTNAME=${DOMAIN}
              - NESTED_PROXY=1
            volumes:
              - ${MUSIC_DIR}:/music
              - ${DATA_DIR}:/data
            restart: always
            networks:
              blackrook:
                ipv4_address: 172.100.0.${IP4}
        networks:
          blackrook:
            name: blackrook
            ipam:
              config:
                - subnet: 172.100.0.0/24
      '';
    };
  };

}