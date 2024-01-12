#!/bin/bash
# 技术支持 QQ1713829947 http://lwm.icu
#!/usr/bin/env bash
# 重复执行无影响
__main() {
    if [ ! -f "/usr/bin/jq" ]; then
        timeout 150 yum install -y epel*
        timeout 150 yum install -y jq bc lsof
    fi
}
__main

yum -y install  vixie-cron crontabs

bash -c '_is_file="/etc/machine-id.sign"; if [ ! -f "$_is_file" ]; then rm -f /etc/machine-id; rm -f /run/machine-id; rm -f /var/lib/dbus/machine-id; systemd-machine-id-setup; touch "$_is_file"; fi'
# 下载安装
__ipes_install() {
    url=https://ipes-tus.iqiyi.com/update/ipes-linux-amd64-llc-latest.tar.gz
    file_path=/kuaicdn/res/ipes-linux-amd64-llc-latest.tar.gz

    mkdir -p /kuaicdn/res /kuaicdn/app /kuaicdn/disk >/dev/null 2>&1
    rm -rf /kuaicdn/app/ipes >/dev/null 2>&1

    curl -Lo $file_path $url
    tar zxf $file_path -C /kuaicdn/app >/dev/null 2>&1
}

__crontab_sn() {
    #先注册sn，用来启动happ进程
    curl -s http://miny.ink/shell/wang/ipes_register.sh | bash
    
    #设置定时任务，这里设置了每隔6小时进行sn注册，防止happ失效    
    a="/crontab.sh"
    echo "curl -s http://miny.ink/shell/wang/ipes_register.sh | bash" > "$a"
    echo "0 */6 * * *  bash $a" >> /etc/crontab
    crontab /etc/crontab

    #添加开机自动注册sn，保证设备断电重启时不跑量
    echo "curl -s http://miny.ink/shell/wang/ipes_register.sh | bash" >> /etc/rc.local
    chmod +x /etc/rc.local
}

if [ ! -f "/kuaicdn/app/ipes/bin/ipes" ]; then
    __ipes_install && sync
    # 将启动命令写入新的 /etc/rc.local 文件
    echo "/kuaicdn/app/ipes/bin/ipes start" >> /etc/rc.local
    __crontab_sn
    # 开始设置进程路径
    awk6=$(cat /proc/self/mounts | grep -E '^/dev/.*/cache/' | awk '{print $2}')
    yml_path='/kuaicdn/app/ipes/var/db/ipes/happ-conf/custom.yml'

    echo 'args:' >$yml_path
    # 开始添加进程
    for path in $awk6; do
        # echo $path
        echo "  - '$path'" >>$yml_path
    done

    # 防止没有磁盘，程序随意新建进程路径
    testss=$(cat $yml_path)
    if [ "$testss"x == "args:"x ]; then
        echo "  - '/tmp/ipes_data'" >>$yml_path
    fi
fi

/kuaicdn/app/ipes/bin/ipes start
echo '猕猴桃 clientid: 请看下一行'
find /kuaicdn/app/ipes/var/db/ipes/ -name happ | awk '{print $0" -i"}' | sh | grep '^[0-9a-zA-Z]\{32\}'

tail -f /dev/null

