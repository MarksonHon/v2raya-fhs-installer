#!/bin/bash

## Pre
if [ -f /usr/local/bin/tput ] || [ -f /usr/bin/tput ] || [ -f /bin/tput ]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)
fi

if [ -f /usr/local/bin/curl ] || [ -f /usr/bin/curl ] || [ -f /bin/curl ]; then
    echo "curl is installed, continue installation."
else
    echo "curl is not installed, please install curl first."
    exit 1
fi

## Urls
GitHub_API_URL="https://api.github.com/repos/v2rayA/v2rayA/releases/latest"
GitHub_Release_URL="https://github.com/v2rayA/v2rayA/releases"
LatestVersion=$(curl -s $GitHub_API_URL | grep 'tag_name' | awk -F '"' '{print $4}' | awk -F 'v' '{print $2}')
DownloadUrlGitHubx64="$GitHub_Release_URL/download/v$LatestVersion/v2raya_linux_x64_$LatestVersion"
DownloadUrlGitHubarm64="$GitHub_Release_URL/download/v$LatestVersion/v2raya_linux_arm64_$LatestVersion"
if [ "$1" == '--use-ghproxy' ]; then
    DownloadUrlx64="https://ghproxy.com/$DownloadUrlGitHubx64"
    DownloadUrlarm64="https://ghproxy.com/$DownloadUrlGitHubarm64"
else
    DownloadUrlx64="$DownloadUrlGitHubx64"
    DownloadUrlarm64="$DownloadUrlGitHubarm64"
fi

CheckLatestVersion(){
    echo "Latest Version is $LatestVersion"
}

CheckCurrentVersion(){
    if [ ! -f /usr/local/bin/v2raya ]; then
        CurrentVersion="none"
    else
        CurrentVersion=$(/usr/local/bin/v2raya --version)
    fi
    echo "Current Version is $CurrentVersion"
}

MakeSystemDService(){
    ServiceFile="/etc/systemd/system/v2raya.service"
    ServiceConf="/etc/systemd/system/v2raya.service.d/"
    echo "Making '/etc/systemd/system/v2raya.service'"
    echo "[Unit]
Description=A Linux web GUI client of Project V which supports V2Ray, Xray, SS, SSR, Trojan and Pingtunnel
Documentation=https://v2raya.org
After=network.target nss-lookup.target iptables.service ip6tables.service nftables.service
Wants=network.target

[Service]
Environment=\"V2RAYA_CONFIG=/usr/local/etc/v2raya\"
Environment=\"V2RAYA_LOG_FILE=/tmp/v2raya.log\"
Type=simple
User=root
LimitNPROC=500
LimitNOFILE=1000000
ExecStart=/usr/local/bin/v2raya
Restart=on-failure

[Install]
    WantedBy=multi-user.target" > /etc/systemd/system/v2raya.service
    if [ ! -d "$ServiceConf" ]; then
        echo "Marking $ServiceConf"
        mkdir -p $ServiceConf
    fi
    systemctl daemon-reload
}

MakeOpenRCService(){
    echo "Making /etc/init.d/v2raya"
    ServiceFile="/etc/init.d/v2raya"
    ServiceConf="/etc/conf.d/v2raya"
    echo "#!/sbin/openrc-run

name=\"v2rayA\"
description=\"A Linux web GUI client of Project V which supports V2Ray, Xray, SS, SSR, Trojan and Pingtunnel\"

command=\"/usr/local/bin/v2raya\"
command_args=\"--log-file /var/log/v2raya/access.log\"
error_log=\"/var/log/v2raya/error.log\"
pidfile=\"/run/\${RC_SVCNAME}.pid\"
command_background=\"yes\"
rc_ulimit=\"-n 30000\"
rc_cgroup_cleanup=\"yes\"

depend() {
    need net
    after net
}

start_pre() {
   export V2RAYA_CONFIG=\"/usr/local/etc/v2raya\"
   if [ ! -d \"/tmp/v2raya/\" ]; then
     mkdir \"/tmp/v2raya\"
   fi
   if [ ! -d \"/var/log/v2raya/\" ]; then
   ln -s \"/tmp/v2raya/\" \"/var/log/\"
   fi
    }" > '/etc/init.d/v2raya'
    if [ ! -f "/etc/conf.d/v2raya" ]; then
        echo "Marking '/etc/conf.d/v2raya'"
        echo "# See wiki to know how to add envs
# example:
# export V2RAYA_ADDRESS=\"0.0.0.0:2017\"
        " > '/etc/conf.d/v2raya'
    fi
}

NoticeUnsafe(){
    echo -e "${GREEN}-----------------------------------------${RESET}"
    echo -e "${GREEN}v2rayA will listen on 0.0.0.0:2017,${RESET}"
    echo -e "${GREEN}However, if you don't want someone else${RESET}"
    echo -e "${GREEN}to know you are running a proxy tool,${RESET}"
    echo -e "${GREEN}you should edit service file to make${RESET}"
    echo -e "${GREEN}v2rayA listen on 127.0.0.1:2017 instead.${RESET}"
    echo -e "${GREEN}Your service file is in this path: ${RESET}"
    echo -e "${GREEN}$ServiceFile ${RESET}"
    echo -e "${GREEN}Your service config is in this path: ${RESET}"
    echo -e "${GREEN}$ServiceConf ${RESET}"
    echo -e "${GREEN}-----------------------------------------${RESET}"
}

GetSystemInformation(){
    SystemType=$(uname)
    SystemArch=$(uname -m)
    if [ $SystemType != Linux ];then
        echo -e ${RED}"No supported system found\!"${RESET}
        echo "This bash script is only for Linux which follows FHS stand,"
        echo "If you are using macOS, please visit:"
        echo "https://github.com/v2rayA/homebrew-v2raya"
        echo "If you are using Windows, please visit:"
        echo "https://github.com/v2rayA/v2raya-scoop"
        exit 9
    fi
}

Download_v2rayA(){
    if [ $SystemArch == x86_64 ];then
        echo "${GREEN}Downloading v2rayA...${RESET}"
        echo "Downloading $DownloadUrlx64"
        curl --progress-bar -L $DownloadUrlx64 -o "/tmp/v2raya_temp"
    fi
    if [ $SystemArch == aarch64 ];then
        echo "${GREEN}Downloading v2rayA...${RESET}[0m"
        echo "Downloading $DownloadUrlarm64"
        curl --progress-bar -L $DownloadUrlarm64 -o "/tmp/v2raya_temp"
    fi
    if [ $SystemArch != x86_64 ] && [ $SystemArch != aarch64 ];then
        echo ${RED}"You have an unsupported system architecture, script will exit now\!"${RESET}
        echo "You can build v2rayA yourself."
        exit 9
    fi
}

StopService(){
    PID_of_v2rayA=$(pidof v2raya)
    if [ -f /etc/systemd/system/v2raya.service ] && [ -n "$PID_of_v2ray"];then
        echo "Stopping v2rayA..."
        systemctl stop v2raya
        v2rayAServiceStopped=1
        elif [ -f /etc/init.d/v2raya ] && [ -n "$PID_of_v2ray"]; then
        echo "Stopping v2rayA..."
        rc-service v2raya stop
        v2rayAServiceStopped=1
    else
        v2rayAServiceStopped=0
    fi
}

StartService(){
    if [ $v2rayAServiceStopped == 1 ] && [ -f /etc/systemd/system/v2raya.service ];then
        echo "Starting v2rayA..."
        systemctl start v2raya
    fi
    if [ $v2rayAServiceStopped == 1 ] && [ -f /etc/init.d/v2raya ]; then
        echo "Starting v2rayA..."
        rc-service v2raya start
    fi
}

InstallService(){
    if [ -f /sbin/openrc-run ]; then
        MakeOpenRCService
        NoticeUnsafe
        chmod +x /etc/init.d/v2raya
        echo ${YELLOW}"If you want to start v2rayA at system startup, please run:"${RESET}
        echo ${YELLOW}"rc-update add v2raya"${RESET}
        elif [ -f /usr/lib/systemd/systemd ]; then
        MakeSystemDService
        NoticeUnsafe
        echo ${YELLOW}"If you want to start v2rayA at system startup, please run:"${RESET}
        echo ${YELLOW}"systemctl enable v2raya"${RESET}
    else
        echo ${YELLOW}"No supported init system found, no service would be installed."${RESET}
        echo ${YELLOW}"However, v2rayA itself will be installed."${RESET}
    fi
}

main(){
    GetSystemInformation
    CheckCurrentVersion
    CheckLatestVersion
    if [ $CurrentVersion == $LatestVersion ];then
        echo "No update available, script exits."
    else
        Download_v2rayA
        StopService
        echo "Installing v2rayA..."
        cp "/tmp/v2raya_temp" "/usr/local/bin/v2raya"
        chmod 755 "/usr/local/bin/v2raya"
        rm "/tmp/v2raya_temp"
        InstallService
        StartService
    fi
}

main "$@"
