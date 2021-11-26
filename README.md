### 介绍

子域名（subfinder）、IP 解析、端口探测（masscan + nmap + naabu）、web 服务识别（httpx）、漏洞探测（nuclei-template）、敏感文件探测（dirsearch）

**重点：只能在授权范围内使用**

### 安装

1. `git clone https://github.com/wzqs/scan_vuls.git`
2. `sudo apt install xsltproc`
3. 安装 dirsearch masscan nmap naabu subfinder httpx nuclei 到 plugins 目录下，除 dirsearch 外其他二进制执行程序需配置环境变量。

### 用法

sudo ./thxall.sh file.txt (可包含 ip 域名 CIDR 格式)

部分功能未开启，若使用需在 main 内删除前缀 #

### 感谢

dirsearch 
masscan 
nmap 
naabu 
subfinder 
httpx 
nuclei 
nmap-bootstrap-xsl
