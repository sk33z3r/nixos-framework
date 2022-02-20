{ CLIENT, DOMAIN, IP4, SQL_IP, SQL_ROOT, SQL_PASS }:

{

  # Filesystem setup
  system.activationScripts."${DOMAIN}" = {
    text = ''
      mkdir -p /var/www/html/${DOMAIN}/wp/htdocs
      mkdir -p /var/www/html/${DOMAIN}/mysql
      chown -R 100:101 /var/www/html/${DOMAIN}/wp/htdocs
      chown -R 999:999 /var/www/html/${DOMAIN}/mysql
    '';
    deps = [];
  };

  # Generate common configs and scripts
  imports = [
    ( import ./scripts/helper.nix { SERVICE = "${CLIENT}"; } )
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "http://172.100.0.${IP4}/";
      HOST_HEADER = "$host";
    } )
  ];

  # Configs and scripts
  environment.etc = {
    "${CLIENT}.compose" = {
      text = ''
        version: '3.7'
        services:
          mysql:
            image: mysql:5.7
            container_name: ${CLIENT}-db
            volumes:
              - /var/www/html/${DOMAIN}/mysql:/var/lib/mysql:rw
            environment:
              MYSQL_ROOT_PASSWORD: "${SQL_ROOT}"
              MYSQL_DATABASE: "wordpress"
              MYSQL_USER: "wordpress"
              MYSQL_PASSWORD: "${SQL_PASS}"
            restart: always
            networks:
              blackrook:
                ipv4_address: 172.100.0.${SQL_IP}
          wordpress:
            image: etopian/alpine-php-wordpress
            container_name: ${CLIENT}
            volumes:
              - /var/www/html/${DOMAIN}/wp:/DATA:rw
            environment:
              VIRTUAL_HOST: "${DOMAIN}"
            restart: always
            depends_on:
              - mysql
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