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
    if [ ! -f /usr/local/bin/v2raya ]; then
    CurrentVersion="none"
    else
    CurrentVersion=$(/usr/local/bin/v2raya --version)
    fi
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

GetSystemInformation(){
    SystemType=$(uname)
    SystemArch=$(uname -m)
}

v2rayAInstallation(){
    if [ $SystemArch == x86_64 ];then
    curl -L $DownloadUrlx64 -o "/tmp/v2raya"
    fi
    if [ $SystemArch == aarch64 ];then
    curl -L $DownloadUrlarm64 -o "/tmp/v2raya"
    fi
    if [ -f /etc/systemd/system/v2raya.service ];then
    echo "Stopping v2raya"
    systemctl stop v2raya
    fi
    if [[ -n $(ps -ef | grep v2raya | gawk '$0 !~/grep/ {print $2}' |tr -s '\n' ' ') ]];then
    kill -15 $(pidof v2raya)
    fi
    mv /tmp/v2raya /usr/local/bin/v2raya
    chmod 555 /usr/local/bin/v2raya
}

main(){
    CheckCurrentVersion
    CheckLatestVersion
    if [ $CurrentVersion != $LatestVersion ];then
        GetSystemInformation
        DownloadUrl
        v2rayAInstallation
        echo "v2rayA new version installed, use systemctl to start, stop or restart it."
        echo " use \"systemctl enable v2raya\" to make v2rayA start at system startup."
        else
        echo "There is no update for v2rayA, you have latest version."
    fi
    if [ ! -f /etc/systemd/system/v2raya.service ];then
        echo "Making '/etc/systemd/system/v2raya.service'"
        MakeSystemDService
    fi    
    if [ ! -d "/etc/systemd/system/v2raya.service.d/" ]; then
        echo "Marking '/etc/systemd/system/v2raya.service.d/'"
        mkdir -p /etc/systemd/system/v2raya.service.d/
    fi
    echo "Starting v2raya"
    systemctl start v2raya
}

main "$@"
