#!/bin/bash

set -x

## Color
if command -v tput > /dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)
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
    echo -e "${RED}""No supported system found!""${RESET}"
    echo "This bash script is only for Linux which follows FHS stand,"
    echo "If you are using macOS, please visit:"
    echo "https://github.com/v2rayA/homebrew-v2raya"
    echo "If you are using Windows, please visit:"
    echo "https://github.com/v2rayA/v2raya-scoop"
    exit 1
fi

## Don't install on Android
if [ -f /system/build.prop ] || [ "$(uname -o)" == "Android" ]; then
    echo "Android is not supported by v2rayA!"
    echo "Please use SagerNet, v2rayNG or v2ray_for_Magisk instead."
    exit 1
fi

## Check args
if [ "$1" != '--force' ] && [ "$1" != '--use-mirror' ] && [ "$1" != '--with-v2ray' ] && [ "$1" != '--with-xray' ] && [ -n "$1" ];then
    echo "${YELLOW}""Usage of $(pwd)/v2raya-fhs-installer.sh:""${RESET}"
    echo "--use-mirror     use v2rayA's mirror server to download (no xray core support yet)"
    echo "--with-v2ray     install v2ray core after installing v2rayA"
    echo "--with-xray      install xray core after installing v2rayA"
    echo "--force          forcw install v2rayA even it has been installed"
    exit 1
fi
while [ $# != 0 ] ; do 
    if [ "$1" == '--use-mirror' ]; then
        use_mirror='yes'
    fi
    if [ "$1" == '--with-v2ray' ]; then
        need_install_v2ray='yes'
    fi
    if [ "$1" == '--with-xray' ]; then
        need_install_xray='yes'
    fi
    if [ "$1" == '--force' ]; then
        force_install='yes'
    fi
    shift 
done

## Installation path
if [ -d /usr/local/bin/ ]; then
    install_path='/usr/local/bin/'
else
    echo "${YELLOW}""v2rayA will install to /usr/bin/, are you sure to continue?""${RESET}"
    echo "Please input \"yes\" to continue:"
    read -t 300 -r we_should_continue
    if [ "$we_should_continue" != 'yes' ]; then
        echo "${RED}""Stop installation""${RESET}"
    else
        install_path='/usr/bin/'
        use_system_share='1'
    fi
fi
## Share path
if [ "$use_system_share" == '1' ]; then
    v2ray_share_path='/usr/share/v2ray/'
    xray_share_path='/usr/share/xray/'
else
    v2ray_share_path='/usr/local/share/v2ray/'
    xray_share_path='/usr/local/share/xray/'
fi

## Urls
## base
if [ "$use_mirror" == 'yes' ]; then
    base_url='https://hubmirror.v2raya.org'
else
    base_url='https://github.com'
fi
## v2rayA
get_v2raya_url(){
    v2raya_latest_tag=$(curl -H "Cache-Control: no-cache" -s https://api.github.com/repos/v2rayA/v2rayA/tags | jq -r ".[]" |  jq -r '.name' | awk 'NR==1 {print; exit}' | awk -F 'v' '{print $2}')
    v2raya_download_url="$base_url"'/v2rayA/v2rayA/releases/download/v'"$v2raya_latest_tag""/v2raya_linux_""$MACHINE"'_'"$v2raya_latest_tag"
    v2raya_hash_url="$v2raya_download_url"'.sha256.txt'
}
## v2ray core
get_v2ray_url(){
    v2ray_latest_tag=$(curl -H "Cache-Control: no-cache" -s https://api.github.com/repos/v2fly/v2ray-core/tags | jq -r ".[]" |  jq -r '.name' | awk 'NR==1 {print; exit}' | awk -F 'v' '{print $2}')
    v2ray_download_url="$base_url""/v2fly/v2ray-core/releases/download/v$v2ray_latest_tag/v2ray-linux-$ARCH.zip"
    v2ray_hash_url="$v2ray_download_url"'.dgst'
}
## xray core
get_xray_url(){
    xray_latest_tag=$(curl -H "Cache-Control: no-cache" -s https://api.github.com/repos/XTLS/xray-core/tags | jq -r ".[]" |  jq -r '.name' | awk 'NR==1 {print; exit}' | awk -F 'v' '{print $2}')
    xray_download_url="https://github.com/XTLS/xray-core/releases/download/v$xray_latest_tag/Xray-linux-$ARCH.zip"
    xray_hash_url="$xray_download_url"'.dgst'
}

## Download
## v2rayA
download_v2raya(){
    echo "${GREEN}""Downloading v2rayA...""${RESET}"
    if ! curl -H "Cache-Control: no-cache" --progress-bar -L "$v2raya_download_url" --output ./v2raya_bin; then
        echo "${RED}""Download v2rayA failed! Check your Internet and try again!""${RESET}"
        exit 1
    fi
    if ! curl -H "Cache-Control: no-cache" -sL "$v2raya_hash_url" --output ./v2raya_hash; then
        echo "${RED}""Download v2rayA hash failed! Check your Internet and try again!""${RESET}"
        exit 1
    fi
    local_v2raya_hash=$(sha256sum ./v2raya_bin | awk -F ' ' '{print$1}')
    remote_v2raya_hash=$(cat ./v2raya_hash)
    if [ "$local_v2raya_hash" != "$remote_v2raya_hash" ]; then
        echo "v2rayA SHA256 mismatch!"
        echo "Expected: $remote_v2raya_hash"
        echo "Actual: $local_v2raya_hash"
        echo "Check your Internet and try again!"
        rm ./v2raya-bin ./v2raya_hash
        exit 1
    fi
}
## v2ray core
download_v2ray(){
    echo "${GREEN}""Downloading v2ray core...""${RESET}"
    if ! curl -H "Cache-Control: no-cache" --progress-bar -L "$v2ray_download_url" --output ./v2ray.zip; then
        echo "${RED}""Download v2ray core failed! Check your Internet and try again!""${RESET}"
        exit 1
    fi
    if ! curl -H "Cache-Control: no-cache" -sL "$v2ray_hash_url" --output ./v2ray_hash; then
        echo "${RED}""Download v2ray core hash failed! Check your Internet and try again!""${RESET}"
        exit 1
    fi
    local_v2ray_hash=$(sha256sum ./v2ray.zip | awk -F ' ' '{print$1}')
    remote_v2ray_hash=$(awk -F '= ' '/256=/ {print $2}' < ./v2ray_hash )
    if [ "$local_v2ray_hash" != "$remote_v2ray_hash" ]; then
        echo "v2ray core SHA256 mismatch!"
        echo "Expected: $remote_v2ray_hash"
        echo "Actual: $local_v2ray_hash"
        echo "Check your Internet and try again!"
        rm ./v2ray.zip ./v2ray_hash
        exit 1
    fi
}
## xray core
download_xray(){
    if ! curl -H "Cache-Control: no-cache" --progress-bar -L "$xray_download_url" --output ./xray.zip; then
        echo "${RED}""Download v2ray core failed! Check your Internet and try again!""${RESET}"
        exit 1
    fi
    if ! curl -H "Cache-Control: no-cache" -sL "$xray_hash_url" --output ./xray_hash; then
        echo "${RED}""Download v2ray core hash failed! Check your Internet and try again!""${RESET}"
        exit 1
    fi
    local_xray_hash=$(sha256sum ./xray.zip | awk -F ' ' '{print$1}')
    remote_xray_hash=$(awk -F '= ' '/256=/ {print $2}' < ./xray_hash )
    if [ "$local_xray_hash" != "$remote_xray_hash" ]; then
        echo "xray core SHA256 mismatch!"
        echo "Expected: $remote_v2ray_hash"
        echo "Actual: $local_v2ray_hash"
        echo "Check your Internet and try again!"
        rm ./xray.zip ./xray_hash
        exit 1 
    fi
}

## Installation
## v2rayA
install_v2raya(){
    mv ./v2raya_bin "$install_path"/v2raya
    chmod 755 "$install_path"v2raya
    rm ./v2raya_hash
}
## v2ray core
install_v2ray(){
    unzip v2ray.zip -d ./v2ray/
    mv ./v2ray/v2ray "$install_path"
    chmod 755 "$install_path"v2ray
    mkdir "$v2ray_share_path"
    mv ./v2ray/*dat "$v2ray_share_path"
    rm -rf ./v2ray ./v2ray_hash
}
## xray core
install_xray(){
    unzip xray.zip -d ./xray/
    mv ./xray/xray "$install_path"
    chmod 755 "$install_path"xray
    mkdir "$xray_share_path"
    mv ./xray/*dat "$xray_share_path"
    rm -rf ./xray ./xray_hash
}

## v2rayA service
## systemd
create_systemd_service(){
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
ExecStart=${install_path}/v2raya
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/v2raya.service
    systemctl daemon-reload
    echo 'systemd service has installed to /etc/systemd/system/v2raya.service'
}
## OpenRC
create_open_rc_service(){
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
    echo "OpenRC service script has installed to /etc/init.d/v2raya"
}
## Stop service while in installation
stop_v2raya(){
    if [ -f /usr/lib/systemd/systemd ] && [ "$(systemctl is-active v2raya)" == "active" ]; then
        echo "${GREEN}Stopping v2raya...${RESET}"
        systemctl stop v2raya
        v2raya_stopped=yes
        echo "${GREEN}Stopped v2rayA${RESET}"
    fi
    if [ -f /etc/init.d/dae ] && [ -f /run/dae.pid ] && [ -n "$(cat /run/dae.pid)" ]; then
        echo "${GREEN}Stopping v2raya...${RESET}"
        /etc/init.d/dae stop
        v2raya_stopped=yes
        echo "${GREEN}Stopped v2rayA${RESET}"
    fi
}
## Start v2rayA if has been stopped
start_v2raya(){
    if [ "$v2raya_stopped" == "yes" ]; then
        if [ -f /etc/systemd/system/v2raya.service ]; then
            systemctl start v2raya
        elif [ -f /etc/init.d/v2raya ]; then
            /etc/init.d/v2raya start
        fi
    fi
}

## Main
current_path=$(pwd)
cd /tmp/ || exit
if [ -f "$install_path"v2raya ]; then
    v2raya_local_version=$("$install_path"v2raya --version)
else
    v2raya_local_version="v0"
fi
if [ "$force_install" == 'yes' ]; then
    get_v2raya_url
    download_v2raya
    we_are_in_installation=yes 
elif ! [ -n "$(echo "$v2raya_local_version" | grep "$v2raya_latest_tag")" ]; then
# if [ "$v2raya_local_version" != "$v2raya_latest_tag" ]; then
    get_v2raya_url
    download_v2raya
    we_are_in_installation=yes 
fi
if [ "$need_install_v2ray" == 'yes' ]; then
    get_v2ray_url
    download_v2ray
fi
if [ "$need_install_xray" == 'yes' ]; then
    get_xray_url
    download_xray
fi
if [ "$we_are_in_installation" == 'yes' ]; then
    stop_v2raya
    install_v2raya
    if [ -f '/usr/lib/systemd/systemd' ]; then
        create_systemd_service
    fi
    if [ -f '/sbin/openrc-run' ] || [ -f '/usr/sbin/openrc-run' ]; then
        create_open_rc_service
    fi
fi
if [ "$need_install_v2ray" == 'yes' ]; then
    install_v2ray
fi
if [ "$need_install_xray" == 'yes' ]; then
    install_xray
fi
start_v2raya
cd "$current_path" || exit