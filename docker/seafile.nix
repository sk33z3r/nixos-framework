{ DOMAIN, EMAIL, PASS, SQL_PASS }:

let

  SERVICE = "seafile";
  IP4 = "70";
  SQLIP = "71";
  MEMIP = "72";
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

  # Generate common configs and scripts
  imports = [
    ../nixos/packages/media.nix
    ( import ./scripts/helper.nix { SERVICE = "${SERVICE}"; } )
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "http://172.100.0.${IP4}/";
      HOST_HEADER = "$host";
    } )
  ];

  # Define docker-compose.yml
  environment.etc = {
    "${SERVICE}.compose" = {
      text = ''
        version: '3.7'
        services:
          db:
            image: mariadb:10.1
            container_name: ${SERVICE}-db
            environment:
              - MYSQL_ROOT_PASSWORD=${SQL_PASS}
              - MYSQL_LOG_CONSOLE=true
            volumes:
              - ${DATA_DIR}/db:/var/lib/mysql
            networks:
              blackrook:
                ipv4_address: 172.100.0.${SQLIP}
          memcached:
            image: memcached:1.5.6
            container_name: ${SERVICE}-memcached
            entrypoint: memcached -m 256
            networks:
              blackrook:
                ipv4_address: 172.100.0.${MEMIP}
          ${SERVICE}:
            image: seafileltd/seafile-mc:latest
            container_name: ${SERVICE}
            volumes:
              - ${DATA_DIR}/shared:/shared
            environment:
              - DB_HOST=172.100.0.${SQLIP}
              - DB_ROOT_PASSWD=${SQL_PASS}
              - TIME_ZONE=America/New_York
              - SEAFILE_ADMIN_EMAIL=${EMAIL}
              - SEAFILE_ADMIN_PASSWORD=${PASS}
              - SEAFILE_SERVER_LETSENCRYPT=false
              - SEAFILE_SERVER_HOSTNAME=${DOMAIN}
            depends_on:
              - db
              - memcached
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