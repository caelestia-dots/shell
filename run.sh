#!/usr/bin/env bash

# 在 Bash 中，我们直接用 VAR=value 的形式定义变量。
# 为了保持变量作用域在脚本或函数内，可以使用 `local`，但这在脚本顶层不是必需的。
dbus='quickshell.dbus.properties.warning = false;quickshell.dbus.dbusmenu.warning = false'
notifs='quickshell.service.notifications.warning = false'
sni='quickshell.service.sni.host.warning = false'

process='QProcess: Destroyed while process'
# $XDG_CACHE_HOME 环境变量在 Bash 和 Fish 中的使用方式相同。
# 使用双引号确保变量能被正确展开。
cache="Cannot open: file://$XDG_CACHE_HOME/caelestia/imagecache/"

# 将多个规则合并到一个变量中，为了清晰起见。
log_rules="$dbus;$notifs;$sni"

# Fish 的 `(dirname (status filename))` 相当于 Bash 的 `$(dirname "$0")`。
# 它会获取当前正在执行的脚本文件所在的目录路径。
script_dir=$(dirname "$0")

# 执行和 Fish 脚本中完全相同的命令，只是语法稍有变化。
# 使用双引号包裹变量是一种良好的编程习惯，可以防止因空格等特殊字符导致的问题。
qs -p "$script_dir" --log-rules "$log_rules" | grep -vF -e "$process" -e "$cache"
