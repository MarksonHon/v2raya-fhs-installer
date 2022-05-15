#! /bin/bash

GitHub_API_URL="https://api.github.com/repos/v2rayA/v2rayA/releases/latest"
GitHub_Release_URL="https://github.com/v2rayA/v2rayA/releases"

CheckLatestVersion(){
    LatestVersion=$(curl -s $GitHub_API_URL | jq '.tag_name' | cut -d'"' -f2 | cut -b 2-10)
    echo "Latest Version is $LatestVersion"
}

DownloadUrl(){
    DownloadUrlx64="$GitHub_Release_URL/download/v$LatestVersion/v2raya_linux_x64_$LatestVersion"
    DownloadUrlarm64="$GitHub_Release_URL/download/v$LatestVersion/v2raya_linux_arm64_$LatestVersion"
}

CheckCurrentVersion(){
    CurrentVersion=$(/usr/local/bin/v2raya --version)
    echo "Current Version is $CurrentVersion"
}

MakeSystemDService(){
    echo "
[Unit]
Description=v2rayA Service
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
}

MakeSystemDServiceOverridesFolder(){
    if [ ! -d "/etc/systemd/system/v2raya.service.d/" ]; then
      mkdir -p /etc/systemd/system/v2raya.service.d/
    fi
}

GetSystemInformation(){
    SystemType=$(uname)
    SystemArch=$(uname -m)
}

v2rayAInstallation(){
    if [ $SystemArch == x86_64 ];then
    curl -L $DownloadUrlx64 -output "/usr/local/bin/v2raya"
    fi
    if [ $SystemArch == aarch64 ];then
    curl -l $DownloadUrlarm64 -output "/usr/local/bin/v2raya"
    fi
}

main(){
    CheckCurrentVersion
    CheckLatestVersion
    GetSystemInformation
    DownloadUrl
    v2rayAInstallation
    MakeSystemDService
    MakeSystemDServiceOverridesFolder
}

main "$@"
