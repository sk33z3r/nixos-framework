{ DOMAIN }:

let

  SERVICE = "heimdall";
  DATA_DIR = "/data/${SERVICE}";
  IP4 = "150";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}
      chown -R 1000:100 ${DATA_DIR}
    '';
    deps = [];
  };

  # Generate common configs and scripts
  imports = [
    ( import ./common.nix { SERVICE = "${SERVICE}"; } )
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "https://172.100.0.${IP4}/";
      HOST_HEADER = "$host";
    } )
  ];

  # Define docker-compose.yml
  environment.etc = {
    "${SERVICE}.compose" = {
      text = ''
        version: "3.7"
        services:
          ${SERVICE}:
            image: linuxserver/heimdall
            container_name: ${SERVICE}
            environment:
              - PUID=1000
              - PGID=100
              - TZ=America/New_York
            volumes:
              - ${DATA_DIR}:/config
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