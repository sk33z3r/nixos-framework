DOMAIN: { config, pkgs, ... }:

let

  SOCKET = config.services.phpfpm.pools.phpuser.socket;
  NGINXPATH = pkgs.nginx;

in

{

  # Filesystem setup
  system.activationScripts."${DOMAIN}" = {
    text = ''
      mkdir -p /var/www/html/${DOMAIN}
    '';
    deps = [];
  };

  # Static site template
  services.nginx.appendHttpConfig = "
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        server_name ${DOMAIN} www.${DOMAIN};
        root /var/www/html/${DOMAIN};
        index index.php;

        # SSL
        ssl_certificate             /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
        ssl_certificate_key         /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
        ssl_trusted_certificate     /etc/letsencrypt/live/${DOMAIN}/chain.pem;

        # . files
        location ~ /\\.(?!well-known) {
            deny all;
        }

        location / {
          fastcgi_split_path_info ^(.+\.php)(/.+)$;
          fastcgi_pass unix:${SOCKET};
          include ${NGINXPATH}/conf/fastcgi_params;
          include ${NGINXPATH}/conf/fastcgi.conf;
        }
    }
  ";

}