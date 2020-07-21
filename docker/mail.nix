{ DOMAIN, DOMAINS_SERVED }:

{

  # Filesystem setup
  system.activationScripts.mail = {
    text = ''
      mkdir -p /mailcow
    '';
    deps = [];
  };

  # Pull the git repository
  #builtins.fetchGit = {
  #  url = "https://github.com/mailcow/mailcow-dockerized.git";
  #  ref = "master";
  #  name = "/mailcow";
  #};

  # Define cronjobs
  services.cron.systemCronJobs = [
    "20 04 * * 0    root    /etc/mailcow-certs.sh"
    "00 05 15 * *   root    /etc/mailcow.sh backup"
  ];

  # Extra aliases
  programs.fish.shellAliases = {
    mailcow = "/etc/mailcow.sh";
  };

  # Configs and scripts
  environment.etc = {
    "mailcow-certs.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        data="/mailcow/data"
        certs="/etc/letsencrypt/live/${DOMAIN}"
        postfix_c=$(docker ps -qaf name=postfix-mailcow)
        dovecot_c=$(docker ps -qaf name=dovecot-mailcow)
        nginx_c=$(docker ps -qaf name=nginx-mailcow)
        # Copy the latest certs
        cp $certs/fullchain.pem $data/assets/ssl/cert.pem
        cp $certs/privkey.pem $data/assets/ssl/key.pem
        # Restart the containers
        docker restart $postfix_c $dovecot_c $nginx_c
      '';
    };
    "mailcow.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        cd /mailcow
        case $1 in
          up) docker-compose up -d;;
          update) ./update.sh;;
          down) docker-compose down;;
          backup)
            tar zcvf /backups/mail_data-$(date +%Y-%m-%d).tar.gz /mailcow/data
            find /backups -mtime +90 -delete
          ;;
          logs) $command logs -f;;
          *) echo "E: Invalid Command"; exit 1;;
        esac
      '';
    };
  };

  # nginx config
  services.nginx.appendHttpConfig = "
    server {
        listen 80;
        listen [::]:80;

        server_name autoconfig.*;
        rewrite ^/(.*)$ /autoconfig.php last;

        location / {
            proxy_pass http://127.0.0.1:8080/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            client_max_body_size 0;
        }
    }

    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        server_name ${DOMAINS_SERVED} autodiscover.* autoconfig.*;

        # SSL
        ssl_certificate             /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
        ssl_certificate_key         /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
        ssl_trusted_certificate     /etc/letsencrypt/live/${DOMAIN}/chain.pem;

        location / {
            proxy_pass                                http://127.0.0.1:8080/;
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

        # . files
        location ~ /\\.(?!well-known) {
            deny all;
        }
    }
  ";

}