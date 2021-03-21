## Docker上部署v2fly

### [照搬手册](https://guide.v2fly.org/app/docker-deploy-v2ray.html)

- 安装：`docker pull v2fly/v2fly-core`

- [客户端配置文件/etc/v2fly/config.json如下](https://guide.v2fly.org/basics/shadowsocks.html)：  
`$ cat /etc/v2fly/config.json` (分别开启了一个Socks5和一个http代理端口)

  ```json
  {
    "inbounds": [
      {
        "port": 443, // 监听端口
        "protocol": "socks", // 入口协议为 SOCKS 5
        "sniffing": {
          "enabled": true,
          "destOverride": ["http", "tls"]
        },
        "settings": {
          "auth": "noauth"  // 不认证
        }
      },
      {
        "port": "442",// 监听端口
        "protocol": "http" // 入口协议为 http
      }
    ],
    "outbounds": [
      {
        "protocol": "shadowsocks",
        "settings": {
          "servers": [
            {
              "address": "serveraddr.com", // Shadowsocks 的服务器地址
              "method": "aes-128-gcm", // Shadowsocks 的加密方式
              "ota": true, // 是否开启 OTA，true 为开启
              "password": "sspasswd", // Shadowsocks 的密码
              "port": 1024  
            }
          ]
        }
      }
    ]
  }
  ```
- 运行Docker：  
  `docker run -d --name v2ray -v /etc/v2fly:/etc/v2ray -p 443:443 -p 442:442 v2fly/v2fly-core  v2ray -config=/etc/v2ray/config.json`

- 查看状态：`docker container ls`

- 启动 V2Ray：`docker container start v2ray`

- 停止 V2Ray：`docker container stop v2ray`

- 重启 V2Ray：`docker container restart v2ray`

- 查看日志：`docker container logs v2ray`

- 更新配置后，需要重新部署容器，命令如下：  

  ```bash
  docker container stop v2ray
  docker container rm v2ray
  docker run -d --name v2ray -v /etc/v2fly:/etc/v2ray -p 443:443 -p 442:442 v2fly/v2fly-core  v2ray -config=/etc/v2ray/config.json
  ```

- 手动更新 V2Ray 的 Docker 镜像：`docker pull v2fly/v2fly-core`

- 自动更新：  
  ```bash
  docker run -d \
      --name watchtower \
      -v /var/run/docker.sock:/var/run/docker.sock \
      containrrr/watchtower
      v2fly/v2fly-core
  ```

### 以下为v2fly服务端配置文件，其实服务端可以不用v2fly，直接用shadowsocks就行。

- 配置文件：  
  ```json
  {
    "inbounds": [
      {
        "port": 1024, // 监听端口
        "protocol": "shadowsocks",
        "settings": {
          "method": "aes-128-gcm",
          "ota": true, // 是否开启 OTA
          "password": "sspasswd"
        }
      }
    ],
    "outbounds": [
      {
        "protocol": "freedom",  
        "settings": {}
      }
    ]
  }
  ```
### 检测有效性：

- 使用curl检测http：`curl -v -x http://127.0.0.1:442 ifconfig.pro`

- 使用curl检测socks5:`curl -v -x socks5://127.0.0.1:443 ifconfig.pro`
