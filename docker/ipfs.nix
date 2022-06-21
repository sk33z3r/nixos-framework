{ DOMAIN, UPLOAD_DIR }:

let

  SERVICE = "ipfs";
  IP4 = "5";
  DATA_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}
      mkdir -p ${UPLOAD_DIR}
    '';
    deps = [];
  };

  # Generate common configs and scripts
  imports = [
    ( import ./scripts/helper.nix { SERVICE = "${SERVICE}"; } )
  ];

  # Extra aliases
  programs.fish.shellAliases = {
    ipfsh = "/etc/ipfs-helper.sh";
  };

  # Scripts
  environment.etc = {
    "ipfs-helper.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        compose="/etc/${SERVICE}.compose"
        command="docker-compose -f $compose -p ${SERVICE}"
        $command ipfs $@
      '';
    };
  };

  # Define docker-compose.yml
  environment.etc = {
    "${SERVICE}.compose" = {
      text = ''
        version: '3.7'
        services:
          ${SERVICE}:
            image: ipfs/go-ipfs
            container_name: ${SERVICE}
            volumes:
              - ${DATA_DIR}:/data/ipfs
              - ${UPLOAD_DIR}:/host
            restart: unless-stopped
            ports:
              - "4001:4001"
              - "127.0.0.1:5001:5001"
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
            proxy_pass                                http://172.100.0.${IP4}:8080/;
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

        location /ui {
            proxy_pass                                http://172.100.0.${IP4}:5001/webui;
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