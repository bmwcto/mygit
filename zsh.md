编辑配置：

`vim ~/.zshrc`

历史记录防止重复：

`setopt hist_ignore_all_dups`

在命令开头用空格防止保存到历史记录：

`setopt hist_ignore_space`

应用配置：

`source ~/.zshrc`

带年月日时分格式输出历史记录：

`history -i`

过滤序号：

`history -i | awk '{$1="";print $0}'`
