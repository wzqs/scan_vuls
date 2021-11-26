### 介绍

子域名（subfinder）、IP 解析、端口探测（masscan + nmap + naabu）、web 服务识别（httpx）、漏洞探测（nuclei-template）、敏感文件探测（dirsearch）

**重点：只能在授权范围内使用**

### 安装

1. `git clone https://github.com/wzqs/scan_vuls.git`
2. `sudo apt install xsltproc`
3. git clone https://github.com/honze-net/nmap-bootstrap-xsl.git # 将 nmap-bootstrap.xsl 放置到与 thxall.sh 同路径下的 static 目录下（手动创建即可
4. 安装 dirsearch masscan nmap naabu subfinder httpx nuclei 到 plugins 目录下，除 dirsearch 外其他二进制执行程序需配置环境变量。

### 用法

screen ./thxall.sh file.txt (可包含 ip 域名 CIDR 格式) #root权限运行

部分功能未开启，若使用需在 main 内删除前缀 #

### TODO

1. 提供自动下载 适配 linux/Mac 不同发行版本所需工具 的脚本
2. 增加使用字典暴力枚举子域名的功能
3. 提供 web 界面查看报告
4. 提供任务完成通知

### 感谢

dirsearch 
masscan 
nmap 
naabu 
subfinder 
httpx 
nuclei 
nmap-bootstrap-xsl
