{ DOMAIN, TOKEN, SQL_PASS }:

let

  SERVICE = "stringer";
  IP4 = "180";
  SQLIP = "181";
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
      DEST = "http://172.100.0.${IP4}:8080";
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
            image: postgres:9.5-alpine
            container_name: ${SERVICE}-psql
            restart: always
            volumes:
              - ${DATA_DIR}:/var/lib/postgresql/data
            environment:
              - POSTGRES_PASSWORD=${SQL_PASS}
              - POSTGRES_USER=${SERVICE}
              - POSTGRES_DB=${SERVICE}
            networks:
              blackrook:
                ipv4_address: 172.100.0.${SQLIP}
          ${SERVICE}:
            image: mdswanson/stringer
            container_name: ${SERVICE}
            depends_on:
              - db
            restart: always
            environment:
              - SECRET_TOKEN=${TOKEN}
              - PORT=8080
              - DATABASE_URL=postgres://${SERVICE}:${SQL_PASS}@172.100.0.${SQLIP}:5432/${SERVICE}
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