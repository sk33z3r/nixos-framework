{ DOMAIN, SQL_PASS, SQL_ROOT }:

let

  SERVICE = "bookstack";
  IP4 = "160";
  SQL_IP = "161";
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
          ${SERVICE}:
            image: linuxserver/bookstack
            container_name: ${SERVICE}
            environment:
              - PUID=1000
              - PGID=100
              - DB_HOST=172.100.0.${SQL_IP}
              - DB_USER=${SERVICE}
              - DB_PASS=${SQL_PASS}
              - DB_DATABASE=${SERVICE}
              - APP_URL=https://${DOMAIN}
            volumes:
              - ${DATA_DIR}:/config
            restart: unless-stopped
            depends_on:
              - ${SERVICE}-db
            networks:
              blackrook:
                ipv4_address: 172.100.0.${IP4}
          ${SERVICE}-db:
            image: linuxserver/mariadb
            container_name: ${SERVICE}-db
            environment:
              - PUID=1000
              - PGID=100
              - MYSQL_ROOT_PASSWORD=${SQL_ROOT}
              - TZ=America/New_York
              - MYSQL_DATABASE=${SERVICE}
              - MYSQL_USER=${SERVICE}
              - MYSQL_PASSWORD=${SQL_PASS}
            volumes:
              - ${DATA_DIR}:/config
            restart: unless-stopped
            networks:
              blackrook:
                ipv4_address: 172.100.0.${SQL_IP}
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