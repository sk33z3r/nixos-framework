{ DOMAIN, SQL_PASS }:

let

  SERVICE = "ttrss";
  APP_URL = "https://${DOMAIN}/tt-rss";
  IP4 = "190";
  SQLIP = "191";
  FPMIP = "192";
  DATA_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}/app
      chown -R 1000:1000 ${DATA_DIR}/app
    '';
    deps = [];
  };

  # Generate common configs and scripts
  imports = [
    ( import ./scripts/helper.nix { SERVICE = "${SERVICE}"; } )
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "http://172.100.0.${IP4}:2015/";
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
            image: postgres:12-alpine
            container_name: ${SERVICE}-psql
            restart: unless-stopped
            volumes:
              - ${DATA_DIR}/db:/var/lib/postgresql/data
            environment:
              - POSTGRES_PASSWORD=${SQL_PASS}
              - POSTGRES_USER=${SERVICE}
            networks:
              blackrook:
                ipv4_address: 172.100.0.${SQLIP}
          app:
            image: cthulhoo/ttrss-fpm-pgsql-static
            container_name: ${SERVICE}-fpm
            restart: unless-stopped
            environment:
              - DB_TYPE=pgsql
              - DB_HOST=172.100.0.${SQLIP}
              - DB_NAME=${SERVICE}
              - DB_USER=${SERVICE}
              - DB_PASS=${SQL_PASS}
              - OWNER_UID=1000
              - OWNER_GID=1000
              - SELF_URL_PATH=${APP_URL}
            volumes:
              - ${DATA_DIR}/app:/var/www/html:rw
            depends_on:
              - db
            networks:
              blackrook:
                ipv4_address: 172.100.0.${FPMIP}
          updater:
            image: cthulhoo/ttrss-fpm-pgsql-static
            container_name: ${SERVICE}-upd
            restart: unless-stopped
            environment:
              - DB_TYPE=pgsql
              - DB_HOST=172.100.0.${SQLIP}
              - DB_NAME=${SERVICE}
              - DB_USER=${SERVICE}
              - DB_PASS=${SQL_PASS}
              - OWNER_UID=1000
              - OWNER_GID=1000
              - SELF_URL_PATH=${APP_URL}
            volumes:
              - ${DATA_DIR}/app:/var/www/html:rw
            depends_on:
              - app
            networks:
              blackrook:
            command: /updater.sh
          web:
            image: cthulhoo/ttrss-web
            container_name: ${SERVICE}
            restart: unless-stopped
            volumes:
              - ${DATA_DIR}/app:/var/www/html:ro
            depends_on:
              - app
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