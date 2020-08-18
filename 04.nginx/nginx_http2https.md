# Nginx 配置301重定向以及反向代理

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
                proxy_pass         http://127.0.0.1:8083;
                if ($http_user_agent ~* (Go--client|curl) ) {
                        return 404;}
        }

}
```
