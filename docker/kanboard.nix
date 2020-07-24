{ DOMAIN, SQL_PASS, SQL_ROOT }:

let

  SERVICE = "kanboard";
  IP4 = "140";
  SQL_IP = "141";
  DATA_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}/{data,plugins}
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
            image: kanboard/kanboard:latest
            container_name: ${SERVICE}
            restart: unless-stopped
            volumes:
              - ${DATA_DIR}/data:/var/www/app/data
              - ${DATA_DIR}/plugins:/var/www/app/plugins
            environment:
              DATABASE_URL: mysql://${SERVICE}:${SQL_PASS}@172.100.0.${SQL_IP}/${SERVICE}
            networks:
              blackrook:
                ipv4_address: 172.100.0.${IP4}
          db:
            image: mariadb:latest
            container_name: ${SERVICE}-db
            command: --default-authentication-plugin=mysql_native_password
            restart: unless-stopped
            environment:
              MYSQL_ROOT_PASSWORD: ${SQL_ROOT}
              MYSQL_DATABASE: ${SERVICE}
              MYSQL_USER: ${SERVICE}
              MYSQL_PASSWORD: ${SQL_PASS}
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