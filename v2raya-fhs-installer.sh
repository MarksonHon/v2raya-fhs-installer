#! /bin/bash

GitHub_API_URL="https://api.github.com/repos/v2rayA/v2rayA/releases/latest"
GitHub_Release_URL="https://github.com/v2rayA/v2rayA/releases"
OSDN_Mirror_URL="https://zh.osdn.net/projects/v2raya/storage/releases"
LatestVersion=$(curl -s $GitHub_API_URL | jq -r '.tag_name' | cut -b 2-16)

CheckLatestVersion(){
    echo "Latest Version is $LatestVersion"
}

GetUrl(){
    DownloadUrlGitHubx64="$GitHub_Release_URL/download/v$LatestVersion/v2raya_linux_x64_$LatestVersion"
    DownloadUrlGitHubarm64="$GitHub_Release_URL/download/v$LatestVersion/v2raya_linux_arm64_$LatestVersion"
    DownloadUrlOSDNx64="$OSDN_Mirror_URL/v$LatestVersion/v2raya_linux_x64_$LatestVersion"
    DownloadUrlOSDNarm64="$OSDN_Mirror_URL/v$LatestVersion/v2raya_linux_arm64_$LatestVersion"
    HttpCodeOSDN=$(curl -w "%{http_code}" -Is $OSDN_Mirror_URL/v$LatestVersion)
    if [ "$HttpCodeOSDN" = "404" ]; then
    DownloadUrlx64="$DownloadUrlGitHubx64"
    DownloadUrlarm64="$DownloadUrlGitHubarm64"
    echo "v2rayA will download from GitHub releases"
    else
    DownloadUrlx64="$DownloadUrlOSDNx64"
    DownloadUrlarm64="$DownloadUrlOSDNarm64"
    echo "v2rayA will download from an OSDM mirror"
    fi
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
    if [ ! -f /etc/systemd/system/v2raya.service ]; then
    echo "Making '/etc/systemd/system/v2raya.service'"
    echo "[Unit]
Description=A Linux web GUI client of Project V which supports V2Ray, Xray, SS, SSR, Trojan and Pingtunnel
Documentation=https://v2raya.org
After=network.target nss-lookup.target iptables.service ip6tables.service
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
fi
if [ ! -d "/etc/systemd/system/v2raya.service.d/" ]; then
    echo "Marking '/etc/systemd/system/v2raya.service.d/'"
    mkdir -p /etc/systemd/system/v2raya.service.d/
fi
}

MakeOpenRCService(){
    if [ ! -f /etc/init.d/v2raya ]; then
    echo "Making /etc/init.d/v2raya"
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
   export V2RAYA_CONFIG="/usr/local/etc/v2raya"
   if [ ! -d \"/tmp/v2raya/\" ]; then 
     mkdir \"/tmp/v2raya\" 
   fi
   if [ ! -d \"/var/log/v2raya/\" ]; then
   ln -s \"/tmp/v2raya/\" \"/var/log/\"
   fi
}" > '/etc/init.d/v2raya'
fi
}

GetSystemInformation(){
    SystemType=$(uname)
    SystemArch=$(uname -m)
    if [ $SystemType != Linux ];then
    echo -e "\033[41;37m No supported system found! \033[0m"
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
    echo -e "\033[42;37m Downloading v2rayA... \033[0m"
    curl -Ls $DownloadUrlx64 -o "/tmp/v2raya_temp"
    fi
    if [ $SystemArch == aarch64 ];then
    echo -e "\033[42;37m Downloading v2rayA... \033[0m"
    curl -Ls $DownloadUrlarm64 -o "/tmp/v2raya_temp"
    fi
    if [ $SystemArch != x86_64 ] && [ $SystemArch != aarch64 ];then
    echo "You have an unsupported system architecture, script will exit now!"
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
    chmod +x /etc/init.d/v2raya
    echo "If you want to start v2rayA at system startup, please run:"
    echo "rc-update add v2raya"
    elif [ -f /usr/lib/systemd/systemd ]; then
    MakeSystemDService
    echo "If you want to start v2rayA at system startup, please run:"
    echo "systemctl enable v2raya"
    else
    echo "No supported init system found, no service would be installed."
    echo "However, v2rayA itself will be installed."
    fi
}

main(){
    GetSystemInformation
    CheckCurrentVersion
    CheckLatestVersion
    if [ $CurrentVersion == $LatestVersion ];then
    echo "No update available, script exits."
    else
    GetUrl
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
