# v2raya-fhs-installer

## Installation Instructions

Install `jq`, `curl` and `bash` on your system(some systems also need to install `pidof` by yourself), then run this command:

```bash
curl -sL https://github.com/MarksonHon/v2raya-fhs-installer/raw/main/v2raya-fhs-installer.sh | sudo bash
```

This script supports `Systemd` and `OpenRC` init system on Linux, if you are using other init systems such as `runit`, `s6` or `dinit`, then you should write service config/script by yourself.

## Service Example

### Systemd Service

```ini
[Unit]
Description=A Linux web GUI client of Project V which supports V2Ray, Xray, SS, SSR, Trojan and Pingtunnel
Documentation=https://v2raya.org
After=network.target nss-lookup.target iptables.service ip6tables.service
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
   export V2RAYA_CONFIG=/usr/local/etc/v2raya
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

## Thanks to

1. V2Ray Systemd Installation Script  
<https://github.com/v2fly/fhs-install-v2ray/blob/master/install-release.sh>

2. V2Ray Alpine Installation Script  
<https://github.com/v2fly/alpinelinux-install-v2ray/blob/master/install-release.sh>

3. Void Linux Wiki  
<https://docs.voidlinux.org/config/services/index.html>