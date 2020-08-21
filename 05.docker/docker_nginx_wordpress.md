# 用docker和nginx搭建一个https的网站

## docker-compose.yml

```
version: '3.1'

services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: wpdb
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wpPass
      WORDPRESS_DB_NAME: wpone
    volumes:
      - ./wordpress:/var/www/html

  wpdb:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: wpone
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wpPass
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - ./wpdb:/var/lib/mysql
```

## nginx_wp.conf

```
server {
        listen 80;
        server_name example.com www.example.com;
        return 301 https://example.com$request_uri;
        server_tokens off;
}

server {
        listen 443 ssl;
        server_name example.com;
        ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
        include /etc/letsencrypt/options-ssl-nginx.conf;
        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

        error_page 403 /error/403.html;
        error_page 404 /error/404.html;
        error_page 405 /error/405.html;
        error_page 500 501 502 503 504 /error/5xx.html;

        location ^~ /error/ {
                internal;
                root /var/www/html;
                }
        location / {
                proxy_set_header   X-Real-IP $remote_addr;
                proxy_set_header   X-Forwarded-For $remote_addr;
                proxy_set_header   Host      $host;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_pass         http://127.0.0.1:8080;
                if ($http_user_agent ~* (Go--client|curl) ) {
                        return 404;}
        }

}
```

## 跑起来

```bash
mkdir -p /home/example
mkdir -p /home/example/wordpress
mkdir -p /home/example/wpdb
cd /home/example
docker-compose up -d
```
