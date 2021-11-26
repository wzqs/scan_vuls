#!/bin/bash
# Author: wzqs
# Date: 2021-09

FILE="$1"
WORKDIR="$(
    cd "$(dirname "$0")"
    pwd -P
)"
RESULTS="$WORKDIR/results"
TMPS="$WORKDIR/tmps"
STATIC="$WORKDIR/static"
PLUGINS="$WORKDIR/plugins"

display_logo() {
    echo -e "
  _______ _    ___   __     _ _ 
 |__   __| |  | \ \ / /    | | |
    | |  | |__| |\ V / __ _| | |
    | |  |  __  | > < / _  | | |
    | |  | |  | |/ . \ (_| | | |
    |_|  |_|  |_/_/ \_\__,_|_|_|  v0.1 \t[*] Intro: an auto utility tools to help find vulns by wzqs                    
"
}

check_args() {
    if [ $# -eq 0 ]; then
        echo -e "\t[!] Error: Please check input parameter!\n"
        echo -e "\t[+] Usage: ./thxall.sh <file-containing-list-of-DOMAINS/IP/CIDR>\n"
        echo -e "\t[+] Example: ./thxall.sh file.txt\n"
        exit 1
    elif [ ! -s $1 ]; then
        echo -e "\t[!] Error: File is empty or does not exists!\n"
        echo -e "\t[+] Usage: ./thxall.sh <file-containing-list-of-DOMAINS/IP/CIDR>\n"
        echo -e "\t[+] Example: ./thxall.sh file.txt\n"
        exit 1
    fi
}

init_config() {
    echo -e "[+] Checking if results and tmps directory already exists."
    if [ -d $RESULTS -a $TMPS ]; then
        echo -e "[-] Directory already exists. Skipping..."
    else
        echo -e "[+] Creating results and tmps directory."
        mkdir -p $RESULTS $TMPS
    fi
    ip_list=$(grep -Po '^([0-9]{1,3}\.){3}[0-9]{1,3}($|/([0-9]{1,2}))$' $FILE >$TMPS/ip_list.tmp)
    domain_list=$(cat $TMPS/ip_list.tmp $FILE | sort | uniq -u >$TMPS/domains.tmp)
}

find_subdomains() {
    echo "[+] Discovering valid subdomains"
    subfinder -dL $TMPS/domains.tmp -silent >$TMPS/domains.txt
    cat $TMPS/domains.txt | sort -n | uniq >$RESULTS/domains.txt
}

resolving_domains() {
    domain_ip=""
    echo "[+] Resolving domains..."

    while read domain; do
        dig_res=$(dig "$domain" +short | grep -Po '((?:(?:25[0-5]|2[0-4]\d|[01]?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d?\d))')
        domain_ip="$domain_ip$domain\n"

        for ((i = 1; i < ${#domain}; i++)); do domain_ip="$domain_ip="; done
        domain_ip="$domain_ip=\n"
        while read address; do
            domain_ip="$domain_ip$address\n"
        done <<<"$dig_res"
        domain_ip="$domain_ip\n"
    done <$RESULTS/domains.txt

    echo -en "$domain_ip" >$TMPS/dns2ip.tmp
    grep -Po '((?:(?:25[0-5]|2[0-4]\d|[01]?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d?\d))' $TMPS/dns2ip.tmp >$TMPS/dns_ip.tmp
    cat $TMPS/ip_list.tmp >>$TMPS/dns_ip.tmp && cat $TMPS/dns_ip.tmp | sort -n | uniq >$RESULTS/all_ip.txt
    cat $RESULTS/all_ip.txt $RESULTS/domains.txt | sort -n | uniq >$RESULTS/allscan.txt
}

enum_ports() {
    echo -e "[+] Running Masscan."
    sudo masscan --top-ports 100 --rate 500 --wait 0 --open -iL $RESULTS/all_ip.txt -oX $STATIC/masscan.xml
    if [ -f "$WORKDIR/paused.conf" ]; then
        sudo rm "$WORKDIR/paused.conf"
    fi
    open_ports=$(cat $STATIC/masscan.xml | grep portid | cut -d "\"" -f 10 | sort -n | uniq | paste -sd,)
    echo -e "[*] Masscan Done!"
    online_hosts=$(cat $STATIC/masscan.xml | grep portid | cut -d "\"" -f 4 | sort -V | uniq >$TMPS/all_ip.tmp)
    echo -e "[+] Running Naabu With Nmap Intergration"
    sudo naabu -p $open_ports -exclude-cdn -iL $TMPS/all_ip.tmp -nmap-cli "sudo nmap -sVC --open -v -Pn -n -T4 -oX $STATIC/nmap.xml"
    sudo xsltproc -o $STATIC/nmap-native.html $STATIC/nmap.xml
    sudo xsltproc -o $RESULTS/nmap-bootstrap.html $STATIC/nmap-bootstrap.xsl $STATIC/nmap.xml
}

scan_https() {
    echo -e "[+] Running httpx..."
    httpx -l $RESULTS/allscan.txt -ports $open_ports -cname -title -web-server -vhost -status-code -tech-detect -o $RESULTS/httpx_res.txt
}

scan_vuls() {
    echo -e "[+] Running nuclei..."
    httpx -l $RESULTS/allscan.txt -ports $open_ports -silent | nuclei -t ~/nuclei-templates/cves/ -severity critical,high,medium -no-interactsh -o $(date "+%y-%m-%d")-vuls.txt
}

search_webfiles() {
    echo -e "[+] Running dirsearch..."
    cat $RESULTS/all_ip.txt $RESULTS/domains.txt >>$RESULTS/allscan.txt
    python3 dirsearch.py -e php,json,htm,js,rar,bak,zip,tgz,txt -l $RESULTS/allscan.txt -t 100 --format html -o report.html
    
}

print_reports() {
    echo -e "[+] Cleaning temp..."
    sudo rm $TMPS/* $STATIC/*.xml $STATIC/nmap-native.html
    echo -e "[+] Congratulations! All tasks has done."
    echo -e "[*] View the All domains at $RESULTS/domains.txt"
    echo -e "[*] View the Nmap HTML reports at $RESULTS/nmap-bootsrap.html"
    echo -e "[*] View the httpx reports at $RESULTS/httpx_res.txt"
    echo -e "[*] View the dirsearch reports at $RESULTS/dirsearch_res.txt"
    echo -e "[*] View the vuls reports at $RESULTS/$(date "+%y-%m-%d")-vuls.txt"
}

main() {
    display_logo
    check_args $FILE
    init_config
    find_subdomains
    resolving_domains
    enum_ports
    scan_https
    #search_webfiles
    #scan_vuls
}

main

