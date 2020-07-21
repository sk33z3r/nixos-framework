{ DOMAIN, SQL_PASS }:

let

  SERVICE = "nextcloud";
  IP4 = "170";
  SQLIP = "171";
  CONFIG_DIR = "/data/${SERVICE}";
  DATA_DIR = "/data/${SERVICE}/data";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}
      mkdir -p ${CONFIG_DIR}
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
        version: '3.7'
        services:
          ${SERVICE}:
            image: linuxserver/nextcloud
            container_name: ${SERVICE}
            volumes:
              - ${CONFIG_DIR}/config:/config
              - ${DATA_DIR}:/data
            environment:
              - PUID=1000
              - PGID=100
              - TIME_ZONE=America/New_York
            restart: always
            networks:
              blackrook:
                ipv4_address: 172.100.0.${IP4}
          db:
            image: mariadb:latest
            container_name: ${SERVICE}-mysql
            environment:
              - MYSQL_ROOT_PASSWORD=${SQL_PASS}
              - MYSQL_LOG_CONSOLE=true
            volumes:
              - ${CONFIG_DIR}/db:/var/lib/mysql
            networks:
              blackrook:
                ipv4_address: 172.100.0.${SQLIP}
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