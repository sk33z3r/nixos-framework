{ DOMAIN }:

let

  SERVICE = "gitea";
  DATA_DIR = "/data/${SERVICE}";
  IP4 = "10";

in

{

  # Filesystem setup
  system.activationScripts.git = {
    text = ''
      mkdir -p ${DATA_DIR}
    '';
    deps = [];
  };

  # Generate common configs and scripts
  imports = [
    ( import ./scripts/helper.nix { SERVICE = "${SERVICE}"; } )
    ../nixos/webhook.nix
  ];

  # Define docker-compose.yml
  environment.etc = {
    "${SERVICE}.compose" = {
      text = ''
        version: '3.7'
        services:
          ${SERVICE}:
            image: gitea/gitea:latest
            container_name: ${SERVICE}
            volumes:
              - ${DATA_DIR}:/data
            ports:
              - "222:22"
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

  # Special nginx config for webhook
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
            proxy_pass                                http://172.100.0.${IP4}:3000/;
            proxy_http_version                        1.1;
            proxy_redirect                            off;
            proxy_set_header Host			                $host;
            proxy_set_header X-Real-IP		            $remote_addr;
            proxy_set_header X-Forwarded-For	        $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto	      $scheme;
            proxy_set_header X-Forwarded-Host	        $host;
            proxy_set_header X-Forwarded-Port	        $server_port;
            client_max_body_size                      500m;
            proxy_buffering                           off;
        }

        location /run {
            proxy_pass                                http://127.0.0.1:4004;
            proxy_http_version                        1.1;
            proxy_redirect                            off;
            proxy_set_header Host			                $host;
            proxy_set_header X-Real-IP		            $remote_addr;
            proxy_set_header X-Forwarded-For	        $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto	      $scheme;
            proxy_set_header X-Forwarded-Host	        $host;
            proxy_set_header X-Forwarded-Port	        $server_port;
            client_max_body_size                      0;
            proxy_buffering                           off;
        }
    }
  ";

}