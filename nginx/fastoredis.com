upstream app_fastoredis {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name fastoredis.com;
    access_log /var/log/nginx/fastoredis.log;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name www.fastoredis.com;
    return 301 https://fastoredis.com$request_uri;

    ssl_certificate /etc/letsencrypt/live/fastoredis.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/fastoredis.com/privkey.pem; # managed by Certbot

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
    ssl_ecdh_curve secp384r1;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
}

server {
    server_name fastoredis.com;
    access_log /var/log/nginx/fastoredis.log;

    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/fastoredis.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/fastoredis.com/privkey.pem; # managed by Certbot    

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
    ssl_ecdh_curve secp384r1;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    # Disable preloading HSTS for now.  You can use the commented out header line that includes
    # the "preload" directive if you understand the implications.
    # add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;

    ssl_dhparam /etc/ssl/certs/dhparam.pem;

    location / {
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_set_header X-NginX-Proxy true;

      proxy_pass http://app_fastoredis;
      proxy_redirect off;
    }
}
# ssl_certificate /etc/nginx/ssl/nginx.crt;
# ssl_certificate_key /etc/nginx/ssl/nginx.key;
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt
# https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04