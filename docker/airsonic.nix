{ DOMAIN, MUSIC_DIR }:

let

  SERVICE = "airsonic";
  IP4 = "60";
  DATA_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}
      mkdir -p ${MUSIC_DIR}
    '';
    deps = [];
  };

  # Generate common configs and scripts
  imports = [
    ../nixos/packages/media.nix
    ( import ./common.nix { SERVICE = "${SERVICE}"; } )
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "http://172.100.0.${IP4}:4040/";
      HOST_HEADER = "$host";
    } )
  ];

  # Configs and scripts
  environment.etc = {
    "${SERVICE}.compose" = {
      text = ''
        version: '3.7'
        services:
          ${SERVICE}:
            image: airsonic/airsonic:latest
            volumes:
              - ${MUSIC_DIR}:/airsonic/music
              - ${DATA_DIR}/data:/airsonic/data
              - ${DATA_DIR}/playlists:/airsonic/playlists
              - ${DATA_DIR}/podcasts:/airsonic/podcasts
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