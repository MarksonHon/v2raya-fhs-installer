#!/bin/bash

# This script is used to remove v2rayA from your system.
# It is a part of v2rayA's FHS installer.

if [ -f /etc/systemd/system/v2raya.service ];then
    systemctl disable v2raya --now
    rm -f /etc/systemd/system/v2raya.service
    rm -rf /etc/system/systemd/v2raya.service.d
    systemctl daemon-reload
fi

if [ -f /etc/init.d/v2raya ];then
    rc-update del v2raya
    /etc/init.d/v2raya stop
    rm -f /etc/init.d/v2raya
    rm -f /etc/conf.d/v2raya
fi

rm -f /usr/local/bin/v2raya

echo "v2rayA has been removed from your system."