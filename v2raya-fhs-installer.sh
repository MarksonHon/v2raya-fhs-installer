#!/bin/bash

## Color
if command -v tput > /dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)
fi

## Systemd service
Create_SystemD_Service(){
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

## OpenRC Service
Create_OpenRC_Service(){
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
    echo '# See wiki to know how to add env
# example:
# export V2RAYA_ADDRESS="0.0.0.0:2017"' > '/etc/conf.d/v2raya'
fi
}

## Notice
Notice_Unsafe(){
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

## Service Control
Stop_Service(){
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

Start_Service(){
    if [ $v2rayAServiceStopped == 1 ] && [ -f /etc/systemd/system/v2raya.service ];then
        echo "Starting v2rayA..."
        systemctl start v2raya
    fi
    if [ $v2rayAServiceStopped == 1 ] && [ -f /etc/init.d/v2raya ]; then
        echo "Starting v2rayA..."
        rc-service v2raya start
    fi
}

Install_Service(){
    if [ -f /sbin/openrc-run ]; then
        Create_OpenRC_Service
        Notice_Unsafe
        chmod +x /etc/init.d/v2raya
        echo ${YELLOW}"If you want to start v2rayA at system startup, please run:"${RESET}
        echo ${YELLOW}"rc-update add v2raya"${RESET}
        elif [ -f /usr/lib/systemd/systemd ]; then
        Create_SystemD_Service
        Notice_Unsafe
        echo ${YELLOW}"If you want to start v2rayA at system startup, please run:"${RESET}
        echo ${YELLOW}"systemctl enable v2raya"${RESET}
    else
        echo ${YELLOW}"No supported init system found, so no service would be installed."${RESET}
        echo ${YELLOW}"However, v2rayA itself will be installed."${RESET}
    fi
}

## Check curl
if ! command -v curl > /dev/null 2>&1; then
    if command -v apt > /dev/null 2>&1; then
    apt update; apt install curl -y
    elif command -v dnf > /dev/null 2>&1; then
    dnf install curl -y
    elif command -v yum > /dev/null  2>&1; then
    yum install curl -y
    elif command -v zypper > /dev/null 2>&1; then
    zypper install --non-interactive curl
    elif command -v pacman > /dev/null 2>&1; then
    pacman -S curl --noconfirm
    elif command -v apk > /dev/null 2>&1; then
    apk add curl
    else
    echo "curl not installed, stop installation, please install curl and try again!"
    exit 1
    fi
fi

## Check URL
GitHub_API_URL="https://api.github.com/repos/v2rayA/v2rayA/releases/latest"
GitHub_Release_URL="https://github.com/v2rayA/v2rayA/releases"
v2rayA_mirror_URL="https://hubmirror.v2raya.org/v2rayA/v2rayA/releases"
Latest_version=$(curl -s $GitHub_API_URL | grep 'tag_name' | awk -F '"' '{print $4}' | awk -F 'v' '{print $2}')
if [[ $(uname) == 'Linux' ]]; then
case "$(uname -m)" in
      'i386' | 'i686')
        MACHINE='x86'
        ;;
      'amd64' | 'x86_64')
        MACHINE='x64'
        ;;
      'armv7' | 'armv7l')
        MACHINE='arm'
        ;;
      'armv8' | 'aarch64')
        MACHINE='arm64'
        ;;
      *)
        echo "error: The architecture is not supported."
        exit 1
        ;;
    esac
else
    echo -e ${RED}"No supported system found!"${RESET}
    echo "This bash script is only for Linux which follows FHS stand,"
    echo "If you are using macOS, please visit:"
    echo "https://github.com/v2rayA/homebrew-v2raya"
    echo "If you are using Windows, please visit:"
    echo "https://github.com/v2rayA/v2raya-scoop"
    exit 1
fi
if [ "$1" == '--use-ghproxy' ]; then
    URL="https://ghproxy.com/$GitHub_Release_URL/download/v$Latest_version/v2raya_linux_""$MACHINE"'_'"$Latest_version"
elif [ "$1" == '--use-mirror' ]; then
    URL="$v2rayA_mirror_URL/download/v$Latest_version/v2raya_linux_""$MACHINE"'_'"$Latest_version"
else
    URL="$GitHub_Release_URL/download/v$Latest_version/v2raya_linux_""$MACHINE"'_'"$Latest_version"
fi
# Local_SHA256=$(sha256sum /tmp/v2raya_temp | awk '{printf $1}')
# Remote_SHA256=$(curl -sL $URL.sha256.txt)

## Installation
PID_of_v2rayA=$(pidof v2raya)
echo -e "${GREEN}Downloading v2rayA for $MACHINE${RESET}"
echo -e "${GREEN}Downloading from $URL${RESET}"
curl --progress-bar -L -o /tmp/v2raya_temp $URL
# if [[ $Local_SHA256 == $Remote_SHA256 ]]; then
#     echo -e "${GREEN}Download success!${RESET}"
# else
#     echo -e "${RED}SHA256 check failed! Check your network and try again!${RESET}"
#     exit 1
# fi
echo -e "${GREEN}Installing v2rayA${RESET}"
if [ ! -d "/usr/local/bin" ]; then
    mkdir -p "/usr/local/bin"
fi
if [ ! -d "/usr/local/etc/v2raya" ]; then
    mkdir -p "/usr/local/etc/v2raya"
fi
Stop_Service
mv /tmp/v2raya_temp /usr/local/bin/v2raya
chmod +x /usr/local/bin/v2raya
Install_Service
Start_Service
echo -e "${GREEN}v2rayA installed successfully!${RESET}"
