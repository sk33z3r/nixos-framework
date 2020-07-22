{ DOMAIN, SQL_PASS, ROOT_PASS, USERNAME, PASSWORD }:

let

  SERVICE = "nextcloud";
  IP4 = "170";
  SQL_IP = "171";
  REDIS_IP = "172";
  DATA_DIR = "/data/${SERVICE}";
  FILES_DIR = "/data/${SERVICE}/data";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}
      mkdir -p ${FILES_DIR}
      chown -R 33:root ${FILES_DIR}
      chmod -R 770 ${FILES_DIR}
    '';
    deps = [];
  };

  # Generate common configs and scripts
  imports = [
    ( import ./common.nix { SERVICE = "${SERVICE}"; } )
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
            image: mariadb
            container_name: ${SERVICE}-db
            command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
            restart: always
            volumes:
              - ${DATA_DIR}/db:/var/lib/mysql
            environment:
              - MYSQL_ROOT_PASSWORD=${ROOT_PASS}
              - MYSQL_PASSWORD=${SQL_PASS}
              - MYSQL_DATABASE=${SERVICE}
              - MYSQL_USER=${SERVICE}
            networks:
              blackrook:
                ipv4_address: 172.100.0.${SQL_IP}
          redis:
            image: redis
            container_name: ${SERVICE}-redis
            restart: always
            volumes:
              - ${DATA_DIR}/redis:/data
            networks:
              blackrook:
                ipv4_address: 172.100.0.${REDIS_IP}
          app:
            image: nextcloud
            container_name: ${SERVICE}
            depends_on:
              - db
              - redis
            volumes:
              - ${DATA_DIR}/app:/var/www/html
              - ${FILES_DIR}:/data
            environment:
              - MYSQL_DATABASE=${SERVICE}
              - MYSQL_USER=${SERVICE}
              - MYSQL_PASSWORD=${SQL_PASS}
              - MYSQL_HOST=172.100.0.${SQL_IP}
              - NEXTCLOUD_TRUSTED_DOMAINS=${DOMAIN}
              - NEXTCLOUD_ADMIN_USER=${USERNAME}
              - NEXTCLOUD_ADMIN_PASSWORD=${PASSWORD}
              - NEXTCLOUD_DATA_DIR=/data
              - REDIS_HOST=172.100.0.${REDIS_IP}
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