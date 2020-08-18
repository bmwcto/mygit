# Nginx配置反向代理以及ssl，并禁止Go--client和curl

```
$ cat akey.conf 
server {
        listen 80;
        server_name akey.local;
        root /home/bmw/akey;
        index index.html;
        listen 443 ssl;
        ssl_certificate /home/bmw/akey/fullchain.pem;
        ssl_certificate_key /home/bmw/akey/privkey.pem;
        error_page 403 /error/403.html;
        error_page 404 /error/404.html;
        error_page 405 /error/405.html;
        error_page 500 501 502 503 504 /error/5xx.html;

        location ^~ /error/ {
                internal;
                root /home/bmw/akey;
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
$ tree /home/bmw/akey
/home/bmw/akey
├── cert.pem
├── chain.pem
├── error
│   └── 404.html
├── fullchain.pem
├── index.html
└── privkey.pem
```

