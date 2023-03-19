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

Install_v2ray(){
    if [ -f /usr/bin/v2ray ]; then
        echo "v2ray is already installed by your package manager, skipping..."
        return
    elif [ -f /usr/local/bin/v2ray ]; then
        v2ray_current_tag="v""$(/usr/local/bin/v2ray version | grep V2Ray | awk '{print $2}')"
        echo ${GREEN}"v2ray core is already installed, checking for updates..."${RESET}
    else
        v2ray_current_tag="v0.0.0"
    fi
    if [ "$v2ray_latest_tag" != "$v2ray_current_tag" ]; then
        echo ${GREEN}"Downloading v2ray core..."${RESET}
        echo ${GREEN}"Downloading from $v2ray_latest_url"${RESET}
        v2ray_latest_hash="$(curl -sL $v2ray_latest_url.dgst | awk -F '= ' '/256=/ {print $2}')"
        curl --progress-bar -L -H "Cache-Control: no-cache" -o "/tmp/v2ray.zip" "$v2ray_latest_url"
        v2ray_local_hash="$(sha256sum /tmp/v2ray.zip | awk '{print $1}')"
         if [ "$v2ray_latest_hash" != "$v2ray_local_hash" ]; then
            echo "v2ray SHA256 mismatch!"
            echo "Expected: $v2ray_latest_hash"
            echo "Actual: $v2ray_local_hash"
            echo "Please try again."
            exit 1
        fi
    echo ${GREEN}"Installing v2ray core..."${RESET}
    echo ${YELLOW}```unzip /tmp/v2ray.zip -d /tmp/v2ray/```${RESET}
    if [ ! -d /usr/local/share/v2ray ]; then
        mkdir -p /usr/local/share/v2ray
    else
        if [ -f /usr/local/share/v2ray/geoip.dat ]; then
             rm /usr/local/share/v2ray/*dat
        fi
    fi
    if [ -f /usr/local/bin/v2ray ]; then
        rm /usr/local/bin/v2ray
    fi
    mv /tmp/v2ray/*dat /usr/local/share/v2ray
    mv /tmp/v2ray/v2ray /usr/local/bin/v2ray
    chmod 755 /usr/local/bin/v2ray
    rm -rf /tmp/v2ray /tmp/v2ray.zip
    echo ${GREEN}"v2ray core installation completed."${RESET}
    else
    echo ${GREEN}"v2ray core is already the latest version."${RESET}       
    fi
}

Install_v2raya(){
    Local_SHA256="$(sha256sum /tmp/v2raya_temp | awk '{print $1}')"
    Remote_SHA256="$(curl -sL $URL.sha256.txt)"
    PID_of_v2rayA=$(pidof v2raya)
    echo -e "${GREEN}Downloading v2rayA for $MACHINE${RESET}"
    echo -e "${GREEN}Downloading from $URL${RESET}"
    curl --progress-bar -L -o /tmp/v2raya_temp $URL
    if [ "$Local_SHA256" != "$Remote_SHA256" ]; then
        echo "v2rayA SHA256 mismatch!"
        echo "Expected: $Remote_SHA256"
        echo "Actual: $Local_SHA256"
        echo "Please try again."
        exit 1
    fi
    echo -e "${GREEN}Installing v2rayA${RESET}"
    if [ ! -d "/usr/local/bin" ]; then
        mkdir -p "/usr/local/bin"
    fi
    if [ ! -d "/usr/local/etc/v2raya" ]; then
        mkdir -p "/usr/local/etc/v2raya"
    fi
    Stop_Service
    cp /tmp/v2raya_temp /usr/local/bin/v2raya
    chmod +x /usr/local/bin/v2raya
    if command -v v2ray > /dev/null 2>&1; then
            if [ ! -f /usr/local/bin/v2ray ]; then
                echo -e "${GREEN}v2ray is already installed by your package manager, skipping...${RESET}"
            else
                Install_v2ray
            fi
        else
        Install_v2ray
    fi
    Install_Service
    Start_Service
    echo -e "${GREEN}v2rayA installed successfully!${RESET}"
    rm -f /tmp/v2raya_temp
}


## Don't install on OpenWrt or Android
if [ -f /etc/openwrt_release ]; then
    echo "OpenWrt is not supported by this script, please"
    echo "install v2rayA for OpenWrt from this link: "
    echo "https://github.com/v2rayA/v2rayA-openwrt"
    exit 1
fi

if [ -f /system/build.prop ] || [ $(uname -o) == "Android" ]; then
    echo "Android is not supported by v2rayA!"
    echo "Please use SagerNet, v2rayNG or v2ray_for_Magisk instead."
    exit 1
fi

## Check curl, unzip, jq
for tool_need in curl unzip jq; do
    if ! command -v $tool_need > /dev/null 2>&1; then
        if command -v apt > /dev/null 2>&1; then
        apt update; apt install $tool_need -y
        elif command -v dnf > /dev/null 2>&1; then
        dnf install $tool_need -y
        elif command -v yum > /dev/null  2>&1; then
        yum install $tool_need -y
        elif command -v zypper > /dev/null 2>&1; then
        zypper install --non-interactive $tool_need
        elif command -v pacman > /dev/null 2>&1; then
        pacman -S $tool_need --noconfirm
        elif command -v apk > /dev/null 2>&1; then
        apk add $tool_need
        else
        echo "$tool_need not installed, stop installation, please install $tool_need and try again!"
        we_should_exit=1
        fi
    fi
done

if [ "$we_should_exit" == "1" ]; then
    exit 1
fi

## Check Arch and OS
if [[ $(uname) == 'Linux' ]]; then
case "$(uname -m)" in
      'i386' | 'i686')
        MACHINE='x86'
        ARCH='32'
        ;;
      'amd64' | 'x86_64')
        MACHINE='x64'
        ARCH='64'
        ;;
      'armv7' | 'armv7l')
        MACHINE='arm'
        ARCH='arm32-v7a'
        ;;
      'armv8' | 'aarch64')
        MACHINE='arm64'
        ARCH='arm64-v8a'
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

## Check URL
Latest_version=$(curl -s https://api.github.com/repos/v2rayA/v2rayA/tags | jq -r ".[]" |  jq -r '.name' | awk 'NR==1 {print; exit}' | awk -F 'v' '{print $2}')
if [ "$1" == '--use-ghproxy' ]; then
    URL="https://ghproxy.com/https://github.com/v2rayA/v2rayA/releases/download/v$Latest_version/v2raya_linux_""$MACHINE"'_'"$Latest_version"
elif [ "$1" == '--use-mirror' ]; then
    URL="https://hubmirror.v2raya.org/v2rayA/v2rayA/releases/download/v$Latest_version/v2raya_linux_""$MACHINE"'_'"$Latest_version"
else
    URL="https://github.com/v2rayA/v2rayA/releases/download/v$Latest_version/v2raya_linux_""$MACHINE"'_'"$Latest_version"
fi

v2ray_latest_tag="$(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | jq -r '.tag_name')"
if [ "$1" == "--use-mirror" ]; then
    v2ray_latest_url="https://hubmirror.v2raya.org/v2fly/v2ray-core/releases/download/$v2ray_latest_tag/v2ray-linux-$ARCH.zip"
elif [ "$1" == "--use-ghproxy" ]; then
    v2ray_latest_url="https://ghproxy.com/https://github.com/v2fly/v2ray-core/releases/download/$v2ray_latest_tag/v2ray-linux-$ARCH.zip"
else
    v2ray_latest_url="https://github.com/v2fly/v2ray-core/releases/download/$v2ray_latest_tag/v2ray-linux-$ARCH.zip"
fi

if [ -f /usr/local/bin/v2raya ]; then
    echo -e "${GREEN}v2rayA is already installed, checking for updates...${RESET}" 
    if [ "$(/usr/local/bin/v2raya --version)" == "$Latest_version" ]; then
        echo -e "${GREEN}v2rayA is already the latest version.${RESET}"
        Install_v2ray
        exit 0
    else
    Install_v2raya
    fi
else
    Install_v2raya
fi