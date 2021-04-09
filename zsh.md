# 安装使用 ohmyzsh

## 安装

1. `apt update && apt install -y curl git zsh`

2. `sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`

## 配置

3. 复制主题文件  
`cp ~/.oh-my-zsh/themes/amuse.zsh-theme ~/.oh-my-zsh/themes/0myamuse.zsh-theme`

4. 编辑主题文件  
`vim ~/.oh-my-zsh/themes/0myamuse.zsh-theme`

    ```zsh-theme
    PROMPT='
    %{$fg_bold[blue]%}%n%{$reset_color%}@[%M] %{$fg_bold[green]%}%d%{$reset_color%}/$(git_prompt_info) watch %{$fg_bold[red]%}%D %*%{$reset_color%}
    $ '
    ```

5. 编辑配置文件  
`vim ~/.zshrc`

    ```zshrc
    #历史记录防止重复
    setopt hist_ignore_all_dups
    #在命令开头用空格防止保存到历史记录
    setopt hist_ignore_space
    #设置主题
    ZSH_THEME="0myamuse"
    #配置程序别名
    alias fuck=/usr/bin/proxychains4
    #设置保存历史记录的最多条数为100万
    HISTSIZE=10000000
    SAVEHIST=10000000
    #设置历史记录输出的默认日期时间格式
    export HIST_STAMPS="yyyy-mm-dd"
    ```

6. 应用配置  
`source ~/.zshrc`

7. 默认使用ZSH  
`chsh -s /bin/zsh`

## 输出历史记录

* 带年月日时分格式输出历史记录：  
`history -i`

* 过滤序号：  
`history -i | awk '{$1="";print $0}'`
