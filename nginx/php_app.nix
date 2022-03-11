{ DOMAIN, SOCKET, NGINXPATH }:

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
        index index.php index.html;

        # SSL
        ssl_certificate             /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
        ssl_certificate_key         /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
        ssl_trusted_certificate     /etc/letsencrypt/live/${DOMAIN}/chain.pem;

        location ~* /(?!index.php|.*\\.(gif|png|css|js|woff|svg|eot|jpg|jpeg|html|htm|zip)$) {
            rewrite ^/(.*)$ /index.php?page=$1;
        }

        # . files
        location ~ /\\.(?!well-known) {
            deny all;
        }

        location ~ \\.php$ {
          fastcgi_pass  unix:${SOCKET};
          fastcgi_index index.php;
          include ${NGINXPATH}/conf/fastcgi_params;
          include ${NGINXPATH}/conf/fastcgi.conf;
        }
    }
  ";

}