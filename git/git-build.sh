#!/bin/bash

function fun_install_git() {
    # 系统时间同步，NTP服务器默认为：cn.pool.ntp.org,  0.rhel.pool.ntp.org, 1.rhel.pool.ntp.org......
    # 防止配置git时出现Clock skew 的问题
    ntpdate cn.pool.ntp.org

    # 安装依赖包
    yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel -y

    # 下载最新包
    wget https://github.com/git/git/archive/master.zip
    unzip master.zip -d git
    cd git/git-master

    # 编译并安装
    make configure
    ./configure --prefix=/usr
    make all
    make install

    cd ../../
    rm -rf master.zip*
    rm -rf git/
}

fun_install_git
exit 0
