## 在无图形界面的服务器上开启ssh-agent自动启动

### 起因

   - 我在Kali上面使用 `ssh-add ~/mykey` 或者 `ssh-add -L` 的时候一切正常，但SSH连上了Debian（Server）后再用却提示：

        Could not open a connection to your authentication agent.

   - 然后我就迷茫了，经过搜索发现临时解决方案是：```eval `ssh-agent -s` ```
   - 可是，这真的只是临时的，临时到了你退出再登录SSH就不能用了，那这有什么意义？
   - 原因是像文章里面说的，ssh-agent 是为图形界面服务的，但我想在我的家庭小服上使用  
     （其实建议最好还是不要在服务器上使用，万一服务器被人拿下呢？）
   - 所以这时候我就接着摸索，有[一篇文章](https://blog.bitisle.net/2020/04/04/run-ssh-agent-ubuntu-server.html)和[一个问答](https://unix.stackexchange.com/questions/339840/how-to-start-and-use-ssh-agent-as-systemd-service)都写了解决方案;
   - 结合这两篇文章，我记录下来如何解决这个问题。

### 解决

   - 因我先找到的是问答，所以我按问答的去解决这个问题，但失败了；  
   - 先 `mkdir -p ~/.config/systemd/user/` 建立相关路径；  
   - 编辑服务文件 `vim ~/.config/systemd/user/ssh-agent.service`；添加：  

        ```
        [Unit]
        Description=SSH key agent

        [Service]
        Type=simple
        Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
        ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

        [Install]
        WantedBy=default.target
        ```

   - 因为我的版本是7.9，高于7.2,所以还要添加一个文件：  
    `echo 'AddKeysToAgent  yes' >> ~/.ssh/config`  
   - 并配置一下权限：`chmod 600 ~/.ssh/config` or `chown $USER ~/.ssh/config`

   - 启用并启动：

        `systemctl --user enable ssh-agent`  
        `systemctl --user start ssh-agent`

   - 原因很简单，所以结合了文章，在`~/.profile`添加了     
     `export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"`  
     然后 `source ~/.profile` 加载一下就解决了。