# v2raya-fhs-installer

## Installation Instructions

Install `curl` and `bash` on your system(some systems also need to install `pidof` by yourself), then run this command:

```bash
sudo bash -c "$(curl -sL -H "Cache-Control: no-cache" https://github.com/MarksonHon/v2raya-fhs-installer/raw/main/v2raya-fhs-installer.sh)"
```
If you need download from mirror:

```bash
sudo bash -c "$(curl -sL -H "Cache-Control: no-cache" https://github.com/MarksonHon/v2raya-fhs-installer/raw/main/v2raya-fhs-installer.sh)" @ --use-mirror
```

Use `--with-v2ray` to install v2ray core, or `--with-xray` to install xray core:

```bash
sudo bash -c "$(curl -sL -H "Cache-Control: no-cache" https://github.com/MarksonHon/v2raya-fhs-installer/raw/main/v2raya-fhs-installer.sh)" @ --with-v2ray
```

If you want to remove v2rayA:

```bash
curl -sL https://github.com/MarksonHon/v2raya-fhs-installer/raw/main/v2raya-fhs-remover.sh | sudo bash
```

This script supports `Systemd` and `OpenRC` init system on Linux, if you are using other init systems such as `runit`, `s6` or `dinit`, then you should write service config/script by yourself.

## Service Example

### Systemd Service

```ini
[Unit]
Description=A Linux web GUI client of Project V which supports V2Ray, Xray, SS, SSR, Trojan and Pingtunnel
Documentation=https://v2raya.org
After=network.target nss-lookup.target iptables.service ip6tables.service nftables.service
Wants=network.target

[Service]
Environment="V2RAYA_CONFIG=/usr/local/etc/v2raya"
Environment="V2RAYA_LOG_FILE=/tmp/v2raya.log"
Type=simple
User=root
LimitNPROC=500
LimitNOFILE=1000000
ExecStart=/usr/local/bin/v2raya
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### OpenRC Service

This service script locales `/etc/init.d/v2raya`:

```sh
#!/sbin/openrc-run

name="v2rayA"
description="A Linux web GUI client of Project V which supports V2Ray, Xray, SS, SSR, Trojan and Pingtunnel"
command="/usr/local/bin/v2raya"
command_args="--log-file /var/log/v2raya/access.log"
error_log="/var/log/v2raya/error.log"
pidfile="/run/${RC_SVCNAME}.pid"
command_background="yes"
rc_ulimit="-n 30000"
rc_cgroup_cleanup="yes"

depend() {
    need net
    after net
}

start_pre() {
   export V2RAYA_CONFIG="/usr/local/etc/v2raya"
   if [ ! -d "/tmp/v2raya/" ]; then 
     mkdir "/tmp/v2raya" 
   fi
   if [ ! -d "/var/log/v2raya/" ]; then
   ln -s "/tmp/v2raya/" "/var/log/"
   fi
}
```

Give the service script executable privilege:

```bash
chmod +x /etc/init.d/v2raya
```

### Runit Service

This script doesn't include a runit service, but you can write it yourself!

Create v2rayA service dictionary:

```sh
mkdir /etc/runit/sv/v2raya
```

Create v2rayA service file:

```sh
touch /etc/runit/sv/v2raya/run
```

Edit v2rayA service file:

```sh
#! /bin/sh

export V2RAYA_CONFIG=/usr/local/etc/v2raya
export V2RAYA_LOG_FILE=/tmp/v2raya.log

exec /usr/local/bin/v2raya
```

Give the service script executable privilege:

```bash
chmod 755 /etc/runit/sv/v2raya/run
```

### Classic SysV Service Script

A SysV service script can work in SysV Init, OpenRC and Systemd (Required systemd-sysv-compact installed).

Note: `start-stop-daemon` should be installed to run this script.
 
```sh
#!/bin/bash 
# chkconfig: 2345 99 01

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
v2rayA_bin=$(which v2raya)

if [ ! -d "/tmp/v2raya/" ]; then 
    mkdir "/tmp/v2raya" 
fi
if [ ! -d "/var/log/v2raya/" ]; then
    ln -s "/tmp/v2raya/" "/var/log/"
fi

export V2RAYA_CONFIG="/usr/local/etc/v2raya"
export V2RAYA_LOG_FILE="/tmp/v2raya/v2raya.log"

case "$1" in
    start)
        echo "Starting V2raya"
        start-stop-daemon --start --background --pidfile /var/run/v2raya.pid --make-pidfile --exec $v2rayA_bin
        ;;

    stop)
        echo "Stopping V2raya"
        start-stop-daemon --stop --pidfile /var/run/v2raya.pid
        ;;

    restart)
        echo "Restarting V2raya"
        start-stop-daemon --stop --pidfile /var/run/v2raya.pid
        sleep 5
        start-stop-daemon --start --background --pidfile /var/run/v2raya.pid --make-pidfile --exec $v2rayA_bin
        ;;

    log)
        echo "Displaying V2raya Logs"
        tail -f /var/log/v2raya/v2raya.log
        ;;
esac
exit 0
```

## Thanks to

1. V2Ray Systemd Installation Script  
<https://github.com/v2fly/fhs-install-v2ray/blob/master/install-release.sh>

2. V2Ray Alpine Installation Script  
<https://github.com/v2fly/alpinelinux-install-v2ray/blob/master/install-release.sh>

3. Void Linux Wiki  
<https://docs.voidlinux.org/config/services/index.html>
