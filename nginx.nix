{ config, pkgs, lib, ... }:

{

  # Filesystem setup
  systemd.services.nginx.serviceConfig = {
    ReadWritePaths = [ "/var/www/" "/run/" "/var/cache/nginx/" ];
    SystemCallFilter = lib.mkForce "";
    #NoNewPrivileges = lib.mkForce false;
    #ProtectSystem = lib.mkForce "";
    #ProtectHome = lib.mkForce false;
    #PrivateTmp = lib.mkForce false;
    #PrivateDevices = lib.mkForce false;
    #ProtectHostname = lib.mkForce false;
    #ProtectKernelTunables = lib.mkForce false;
    #ProtectKernelModules = lib.mkForce false;
    #ProtectControlGroups = lib.mkForce false;
    #LockPersonality = lib.mkForce false;
    RestrictRealtime = lib.mkForce false;
    RestrictSUIDSGID = lib.mkForce false;
    #PrivateMounts = lib.mkForce false;
    #SystemCallArchitectures = lib.mkForce "";
    #MemoryDenyWriteExecute = lib.mkForce "";
    #UMask = lib.mkForce "0002";
  };

  system.activationScripts = {
    nginx = {
      text = ''
        mkdir -p /var/www/html
        mkdir -p /var/www/logs
        mkdir -p /var/www/_letsencrypt
        chown -R root:root /var/www
        chmod -R 755 /var/www
        chmod -R 775 /var/cache/nginx
        mkdir -p /etc/ssl/certs
      '';
      deps = [];
    };
    dhparam = {
      text = ''
        touch /etc/ssl/certs/dh2048_param.pem
      '';
      deps = [];
    };
  };

  # Extra packages
  environment.systemPackages = with pkgs; [
    nginx certbot vnstat apacheHttpd
  ];

  # Extra aliases
  programs.fish.shellAliases = {
    certbot-helper = "/etc/certbot-helper.sh";
  };

  # Define cronjobs
  services.cron.systemCronJobs = [
    "00 04 * * *    root    /etc/certbot-helper.sh renew"
    "00 04 15 * *    root    /etc/log-rotate.sh"
  ];

  # Open extra ports
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Enable vnstat
  services.vnstat.enable = true;

  # Scripts
  environment.etc = {
    "certbot-helper.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        dhparamFile="/etc/ssl/certs/dh2048_param.pem"
        case $1 in
            renew)
                certbot renew &&
                systemctl restart nginx.service
            ;;
            sign)
                case $2 in
                    test)
                        certbot certonly --test-cert \
                            --webroot -w /var/www/_letsencrypt \
                            --agree-tos --non-interactive \
                            --email systems@blackrookllc.com \
                            -d $3
                    ;;
                    *)
                        certbot certonly \
                            --webroot -w /var/www/_letsencrypt \
                            --agree-tos --non-interactive \
                            --email systems@blackrookllc.com \
                            -d $2
                    ;;
                esac
            ;;
            dhparam)
                echo "** Regenerating Diffie-Hellman Parameters"
                openssl dhparam -out $dhparamFile 4096
            ;;
            *)
                echo -e "Uses:\n  $0 renew\n  $0 sign example.com\n  $0 sign test example.com\n  $0 dhparam"
                exit 1
            ;;
        esac
      '';
    };
    "log-rotate.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # Set script variables
        logPath="/var/www/logs"
        date=$(date +"%Y%m%d")
        # Change log name
        mv -f $logPath/access.log $logPath/access.log.$date
        # Force nginx to re-open its logs
        kill -USR1 `cat /var/spool/nginx/logs/nginx.pid`
        sleep 1
        # Zip rotated log
        gzip -f $logPath/access.log.$date
      '';
    };
  };

  # Setup NGINX
  services.nginx = {
    enable = true;
    user = "root";
    group = "root";
    package = pkgs.nginxMainline;
    statusPage = false;
    appendConfig = "
      worker_processes auto;
      worker_rlimit_nofile 65535;
      user root root;
    ";
    eventsConfig = "
      multi_accept on;
      worker_connections 65535;
    ";
    clientMaxBodySize = "2G";
    sslCiphers = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256";
    sslDhparam = "/etc/ssl/certs/dh2048_param.pem";
    appendHttpConfig = "
      charset utf-8;
      sendfile off;
      tcp_nopush on;
      tcp_nodelay on;
      log_not_found off;

      # logging
      map $remote_addr $ip_anonym1 {
        default 0.0.0;
        \"~(?P<ip>(\\d+)\\.(\\d+)\\.(\\d+))\\.\\d+\" $ip;
        \"~(?P<ip>[^:]+:[^:]+):\" $ip;
      }

      map $remote_addr $ip_anonym2 {
        default .0;
        \"~(?P<ip>(\\d+)\\.(\\d+)\\.(\\d+))\\.\\d+\" .0;
        \"~(?P<ip>[^:]+:[^:]+):\" ::;
      }

      map $ip_anonym1$ip_anonym2 $ip_anonymized {
        default 0.0.0.0;
        \"~(?P<ip>.*)\" $ip;
      }

      log_format anonymized '$ip_anonymized - $remote_user [$time_local] '
        '\"$request\" $status $body_bytes_sent '
        '\"$http_referer\" \"$http_user_agent\"';

      access_log /var/www/logs/access.log anonymized;
      error_log /var/www/logs/error.log warn;

      # SSL
      ssl_session_timeout 1d;
      ssl_session_cache shared:SSL:50m;
      ssl_session_tickets off;

      # modern configuration
      ssl_prefer_server_ciphers on;

      # OCSP Stapling
      ssl_stapling off;

      # gzip
      gzip on;
      gzip_disable \"msie6\";

      gzip_comp_level 6;
      gzip_min_length 1100;
      gzip_buffers 16 8k;
      gzip_proxied any;
      gzip_types
          text/plain
          text/css
          text/js
          text/xml
          text/javascript
          application/javascript
          application/x-javascript
          application/json
          application/xml
          application/rss+xml
          application/x-font-opentype
          image/svg+xml;

      add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;
      add_header X-Frame-Options \"SAMEORIGIN\";
      add_header X-XSS-Protection \"1; mode=block\";
      add_header X-Content-Type-Options nosniff;
      #add_header Content-Security-Policy \"default-src https: data: font: wss: 'unsafe-eval' 'unsafe-inline'; script-src https: 'unsafe-eval' 'unsafe-inline'; style-src https: 'unsafe-eval' 'unsafe-inline'\" always;
      #add_header Content-Security-Policy \"default-src https: data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com/cv/js/sender/v1/cast_sender.js https://www.youtube.com/iframe_api https://s.ytimg.com; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; frame-ancestors 'self'\";

      # HTTP redirect
      server {
          listen 80 default_server;
          listen [::]:80 default_server;

          server_name _;

          location ^~ /.well-known/acme-challenge/ {
              root /var/www/_letsencrypt;
          }

          location / {
              return 301 https://$http_host$request_uri;
          }
      }
    ";
  };

}