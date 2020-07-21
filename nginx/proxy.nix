{ DOMAIN, DEST, HOST_HEADER }:

{

  # Reverse proxy template
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
            proxy_pass                                ${DEST};
            proxy_http_version                        1.1;
            proxy_redirect                            off;
            proxy_set_header Host			                ${HOST_HEADER};
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