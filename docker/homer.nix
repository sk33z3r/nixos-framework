{ DOMAIN }:

let

  SERVICE = "homer";
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
    ( import ./scripts/helper.nix { SERVICE = "${SERVICE}"; } )
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "https://172.100.0.${IP4}:8080/";
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
            image: b4bz/homer
            container_name: ${SERVICE}
            environment:
              - UID=1000
              - GID=100
            volumes:
              - ${DATA_DIR}:/www/assets
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