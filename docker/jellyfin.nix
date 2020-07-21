{ DOMAIN, MUSIC_DIR, VID_DIR, AUDIOBOOKS, EBOOKS }:

let

  SERVICE = "jellyfin";
  IP4 = "65";
  DATA_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}/{config,cache}
      mkdir -p ${VID_DIR}
      mkdir -p ${MUSIC_DIR}
      mkdir -p ${AUDIOBOOKS}
      chown -R 1000:100 ${DATA_DIR} ${VID_DIR} ${MUSIC_DIR} ${AUDIOBOOKS}
    '';
    deps = [];
  };

  # Setup cronjob
  services.cron = {
    enable = true;
    systemCronJobs = [
      "00 */12 * * *    root    chown -R 1000:100 ${DATA_DIR} ${VID_DIR} ${MUSIC_DIR} ${AUDIOBOOKS}"
    ];
  };

  # Generate common configs and scripts
  imports = [
    ../nixos/packages/media.nix
    ( import ./common.nix { SERVICE = "${SERVICE}"; } )
  ];

  # Define docker-compose.yml
  environment.etc = {
    "${SERVICE}.compose" = {
      text = ''
        version: '3.7'
        services:
          ${SERVICE}:
            image: jellyfin/jellyfin
            container_name: ${SERVICE}
            user: 1000:100
            volumes:
              - ${DATA_DIR}/config:/config
              - ${DATA_DIR}/cache:/cache
              - ${VID_DIR}:/media/video
              - ${MUSIC_DIR}:/media/music
              - ${AUDIOBOOKS}:/media/books/audiobooks
              - ${EBOOKS}:/media/books/books
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

  # Special jellyfin nginx config
  services.nginx.appendHttpConfig = "
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        server_name ${DOMAIN};

        # SSL
        ssl_certificate             /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
        ssl_certificate_key         /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
        ssl_trusted_certificate     /etc/letsencrypt/live/${DOMAIN}/chain.pem;

        location / {
            proxy_pass                                http://172.100.0.${IP4}:8096/;
            proxy_http_version                        1.1;
            proxy_set_header Host                     $host;
            proxy_set_header X-Real-IP                $remote_addr;
            proxy_set_header X-Forwarded-For          $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto        $scheme;
            proxy_set_header X-Forwarded-Protocol     $scheme;
            proxy_set_header X-Forwarded-Host         $http_host;
            client_max_body_size                      0;
            proxy_buffering                           off;
        }

        location /socket {
            proxy_pass                                http://172.100.0.${IP4}:8096/socket;
            proxy_http_version                        1.1;
            proxy_set_header                          Upgrade $http_upgrade;
            proxy_set_header                          Connection \"upgrade\";
            proxy_set_header Host                     $host;
            proxy_set_header X-Real-IP                $remote_addr;
            proxy_set_header X-Forwarded-For          $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto        $scheme;
            proxy_set_header X-Forwarded-Protocol     $scheme;
            proxy_set_header X-Forwarded-Host         $http_host;
            client_max_body_size                      0;
            proxy_buffering                           off;
        }

        # . files
        location ~ /\\.(?!well-known) {
            deny all;
        }
    }
  ";

}