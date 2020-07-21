{ SOURCE, DEST }:

{

  # Redirect template
  services.nginx.appendHttpConfig = "
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        server_name ${SOURCE} www.${SOURCE};

        # SSL
        ssl_certificate             /etc/letsencrypt/live/${SOURCE}/fullchain.pem;
        ssl_certificate_key         /etc/letsencrypt/live/${SOURCE}/privkey.pem;
        ssl_trusted_certificate     /etc/letsencrypt/live/${SOURCE}/chain.pem;

        return 307 https://${DEST};

        # . files
        location ~ /\\.(?!well-known) {
            deny all;
        }
    }
  ";

}