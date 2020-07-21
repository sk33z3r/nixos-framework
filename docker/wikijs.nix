{ DOMAIN, SQL_PASS }:

let

  SERVICE = "wikijs";
  IP4 = "40";
  SQL_IP = "41";
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
    ( import ./common.nix { SERVICE = "${SERVICE}"; } )
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "http://172.100.0.${IP4}:3000/";
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
            image: postgres:11-alpine
            container_name: ${SERVICE}-db
            environment:
              POSTGRES_DB: ${SERVICE}
              POSTGRES_PASSWORD: ${SQL_PASS}
              POSTGRES_USER: ${SERVICE}
            logging:
              driver: "none"
            restart: unless-stopped
            volumes:
              - db-data:/var/lib/postgresql/data
            networks:
              blackrook:
                ipv4_address: 172.100.0.${SQL_IP}
          ${SERVICE}:
            image: requarks/wiki:2
            container_name: ${SERVICE}
            depends_on:
              - db
            environment:
              DB_TYPE: postgres
              DB_HOST: 172.100.0.${SQL_IP}
              DB_PORT: 5432
              DB_USER: ${SERVICE}
              DB_PASS: ${SQL_PASS}
              DB_NAME: ${SERVICE}
            volumes:
              - ${DATA_DIR}:/wiki/data/content/wikijs
            restart: unless-stopped
            networks:
              blackrook:
                ipv4_address: 172.100.0.${IP4}
        volumes:
          db-data:
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