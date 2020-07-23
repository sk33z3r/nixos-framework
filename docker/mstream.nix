{ DOMAIN, MUSIC_DIR, WEB_PASS }:

let

  SERVICE = "mstream";
  IP4 = "60";
  DATA_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}
      mkdir -p ${MUSIC_DIR}
      chown -R root:root ${DATA_DIR}
    '';
    deps = [];
  };

  # Generate common configs and scripts
  imports = [
    ../nixos/packages/media.nix
    ( import ./scripts/helper.nix { SERVICE = "${SERVICE}"; } )
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "http://172.100.0.${IP4}:3000/";
      HOST_HEADER = "$host";
    } )
  ];

  # Configs and scripts
  environment.etc = {
    "${SERVICE}.compose" = {
      text = ''
        version: "3.7"
        services:
          ${SERVICE}:
            image: linuxserver/mstream
            container_name: ${SERVICE}
            environment:
              - PUID=0
              - PGID=0
              - USER=blackrook
              - PASSWORD=${WEB_PASS}
              - USE_JSON=false
              - TZ=America/New_York
            volumes:
              - ${DATA_DIR}:/config
              - ${MUSIC_DIR}:/music
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