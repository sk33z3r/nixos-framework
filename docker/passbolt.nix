{ DOMAIN, VID_DIR, SQL_PASS, SQL_ROOT }:

let

  SERVICE = "passbolt";
  IP4 = "61";
  SQL_IP = "62";
  DATA_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}/{mysql,gpg,jwt}
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

  # Define docker-compose.yml and Dockerfile
  environment.etc = {
    "${SERVICE}.compose" = {
      text = ''
        version: '3.7'
        services:
          db:
            image: mariadb:latest
            restart: unless-stopped
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
            image: passbolt/passbolt:latest-ce
            restart: unless-stopped
            container_name: ${SERVICE}
            tty: true
            depends_on:
              - db
            environment:
              APP_FULL_BASE_URL: https://${DOMAIN}
              DATASOURCES_DEFAULT_HOST: 172.100.0.${SQL_IP}
              DATASOURCES_DEFAULT_USERNAME: ${SERVICE}
              DATASOURCES_DEFAULT_PASSWORD: ${SQL_PASS}
              DATASOURCES_DEFAULT_DATABASE: ${SERVICE}
            volumes:
              - ${DATA_DIR}/gpg:/etc/passbolt/gpg
              - ${DATA_DIR}/jwt:/etc/passbolt/jwt
            command: ["/usr/bin/wait-for.sh", "-t", "0", "172.100.0.${SQL_IP}:3306", "--", "/docker-entrypoint.sh"]
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