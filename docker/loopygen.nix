{ DOMAIN }:

let

  SERVICE = "loopygen";
  IP4 = "6";
  COLLECTIONS_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${COLLECTIONS_DIR}
    '';
    deps = [];
  };

  # Generate common configs and scripts
  imports = [
    ( import ./scripts/helper.nix { SERVICE = "${SERVICE}"; } )
  ];

  # Extra aliases
  programs.fish.shellAliases = {
    loopygen-cli = "/etc/loopygen-cli.sh";
  };

  # /etc files
  environment.etc = {
    "loopygen-cli.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash

        name="loopygen-cli"
        tag="sk33z3r/$name"

        update() {
            docker pull $tag
        }

        usage() {
        cat <<EOF

            LooPyGen CLI Utility Script

            Usage: $0 [command]

            Commands:
            update                | Pull the latest image
            secrets               | Force remove the secrets Docker volume
            {command}             | Run a command inside the container

        EOF
        }

        case $1 in
            update) update;;
            secrets) docker volume rm -f $name;;
            -h|-help|help) usage;;
            cid) # only mount local directory and set a new workdir inside the container
                docker run -it --rm --name $name \
                    -w /scan \
                    -v $PWD:/scan \
                    $tag "$@"
            ;;
            *) # run a command inside a self-destructing container
                docker run -it --rm --name $name \
                    -v $name:/loopygen/.secrets \
                    -v ${COLLECTIONS_DIR}:/loopygen/collections:rw \
                    $tag "$@"
            ;;
        esac
      '';
    };
    "${SERVICE}.compose" = {
      text = ''
        version: '3.7'
        services:
          ${SERVICE}:
            image: sk33z3r/loopygen
            container_name: ${SERVICE}
            volumes:
              - ${COLLECTIONS_DIR}:/loopygen/collections
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

  # Special loopygen nginx config
  services.nginx.appendHttpConfig = "
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        server_name ${DOMAIN};

        # SSL
        ssl_certificate             /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
        ssl_certificate_key         /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
        ssl_trusted_certificate     /etc/letsencrypt/live/${DOMAIN}/chain.pem;

        #satisfy any;
        #allow 192.168.1.1/24;
        #deny  all;
        auth_basic 'LooPyGen Access';
        auth_basic_user_file /root/.htpasswd;

        location / {
            proxy_pass                                http://172.100.0.${IP4}/;
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

        # . files
        location ~ /\\.(?!well-known) {
            deny all;
        }
    }
  ";

}