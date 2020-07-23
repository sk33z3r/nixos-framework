{ DOMAIN, VID_DIR, SQL_PASS, SQL_ROOT }:

let

  SERVICE = "streama";
  IP4 = "50";
  SQL_IP = "51";
  DATA_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}/mysql
      mkdir -p ${VID_DIR}
    '';
    deps = [];
  };

  # Generate common configs and scripts
  imports = [
    ../nixos/packages/media.nix
    ( import ./scripts/helper.nix { SERVICE = "${SERVICE}"; } )
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "http://172.100.0.${IP4}:8080/";
      HOST_HEADER = "$host";
    } )
  ];

  # Define docker-compose.yml and Dockerfile
  environment.etc = {
    "${SERVICE}.compose" = {
      text = ''
        version: '3.7'
        services:
          mysql:
            image: mysql:5.7
            container_name: ${SERVICE}-db
            volumes:
              - ${DATA_DIR}/mysql:/var/lib/mysql
            environment:
              MYSQL_ROOT_PASSWORD: ${SQL_ROOT}
              MYSQL_USER: ${SERVICE}
              MYSQL_DATABASE: ${SERVICE}
              MYSQL_PASSWORD: ${SQL_PASS}
            networks:
              blackrook:
                ipv4_address: 172.100.0.${SQL_IP}

          ${SERVICE}:
            build:
              dockerfile: /etc/${SERVICE}.dockerfile
              context: /build
            image: blackrook/${SERVICE}:latest
            container_name: ${SERVICE}
            volumes:
              - ${VID_DIR}:/data
            depends_on:
              - mysql
            environment:
              ACTIVE_PROFILE: mysql
              MYSQL_HOST: 172.100.0.${SQL_IP}
              MYSQL_PORT: 3306
              MYSQL_DB: streama
              MYSQL_USER: streama
              MYSQL_PASSWORD: ${SQL_PASS}
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
    "${SERVICE}.dockerfile" = {
      text = ''
        FROM gkiko/streama:latest

        RUN echo "#!/usr/bin/env bash\njava -Dgrails.env=\''$ACTIVE_PROFILE -jar /app/streama/streama.jar" > /app/entrypoint.sh
        RUN chmod a+x /app/entrypoint.sh

        ENTRYPOINT [ "/app/entrypoint.sh" ]
      '';
    };
  };

}