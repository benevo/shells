#! /bin/bash
# chkconfig: 2345 55 25
# Description: Startup script for Ngrok on Debian. Place in /etc/init.d and
# run 'update-rc.d -f ngrokd defaults', or use the appropriate command on your
# distro. For CentOS/Redhat run: 'chkconfig --add ngrokd'
#=======================================================
#   System Required:  CentOS/Debian/Ubuntu (32bit/64bit)
#   Description:  Manager for Ngrok, Written by Clang
#   Author: Clang <admin@clangcn.com>
#   Intro:  http://clangcn.com
#=======================================================
### BEGIN INIT INFO
# Provides:          ngrok
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the ngrok
# Description:       starts ngrok using start-stop
### END INIT INFO

#PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
ProgramName="Ngrok"

str_ngrok_dir="/usr/local/ngrok"
str_dir_shell=$(cd `dirname $0`; pwd)
str_dir_http_download_root="http://192.168.10.106:19870"
ProgramPath="${str_ngrok_dir}/bin"
NAME=ngrokd
BIN=${ProgramPath}/${NAME}
CONFIGFILE=${str_ngrok_dir}/.ngrok_config.sh
LOGFILE=${str_ngrok_dir}/ngrok.log
SCRIPTNAME=/etc/init.d/${NAME}
PID_DIR=/var/run
PID_FILE=$PID_DIR/ngrok_clang.pid
version="v5.6"
manage_port="4446"
RET_VAL=0

[ -x $BIN ] || { 
    echo "$BIN has no -x priviliage"    
    exit 0 
}

fun_clang_cn()
{
    return 0
    echo ""
    echo "#############################################################"
    echo "#  Manager Ngrok ${version} for CentOS/Debian/Ubuntu (32bit/64bit)"
    echo "#  Intro: http://clang.cn"
    echo "#"
    echo "#  Author: Clang <admin@clangcn.com>"
    echo "#"
    echo "#############################################################"
    echo ""
}

fun_check_run()
{
    if netstat -tnpl | grep -q ${NAME};then
        return 0
    else
        rm -f $PID_FILE
        return 1
    fi
}
fun_load_config(){    
    if [ ! -r ${CONFIGFILE} ]; then
        echo "config file ${CONFIGFILE} not found"
        return 1
    else
        . ${CONFIGFILE}
        log_level=""
        [ -n "${loglevel}" ] && log_level=" -log-level=\"${loglevel}\""
        cd ${str_ngrok_dir}
    fi
}
fun_check_port(){
    fun_load_config
    strHttpPort=""
    strHttpsPort=""
    strRemotePort=""
    strManPort=""
    strHttpPort=`netstat -ntl | grep "\b:${http_port}\b"`
    strHttpsPort=`netstat -ntl | grep "\b:${https_port}\b"`
    strRemotePort=`netstat -ntl | grep "\b:${remote_port}\b"`
    strManagePort=`netstat -ntl | grep "\b:${manage_port}\b"`
    if [ -n "${strHttpPort}" ] || [ -n "${strHttpsPort}" ] || [ -n "${strRemotePort}" ] || [ -n "${strManagePort}" ]; then
        [ -n "${strHttpPort}" ] && str_http_port="\"${http_port}\" "
        [ -n "${strHttpsPort}" ] && str_https_port="\"${https_port}\" "
        [ -n "${strRemotePort}" ] && str_remote_port="\"${remote_port}\" "
        [ -n "${strManagePort}" ] && str_manage_port="\"${manage_port}\" "
        echo ""
        echo "Error: Port ${str_http_port}${str_https_port}${str_remote_port}${str_manage_port}is used,view relevant port:"
        [ -n "${strHttpPort}" ] && netstat -ntlp | grep "\b:${http_port}\b"
        [ -n "${strHttpsPort}" ] && netstat -ntlp | grep "\b:${https_port}\b"
        [ -n "${strRemotePort}" ] && netstat -ntlp | grep "\b:${remote_port}\b"
        [ -n "${strManagePort}" ] && netstat -ntlp | grep "\b:${manage_port}\b"
        return 1
    fi
}
# fun_check_port && exit 0

fun_randstr(){
  index=0
  strRandomPass=""
  for i in {a..z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {A..Z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {0..9}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {1..16}; do strRandomPass="$strRandomPass${arr[$RANDOM%$index]}"; done
  echo $strRandomPass
}

fun_start()
{
    if [ "${arg1}" = "start" ]; then
      fun_clang_cn
    fi
    if [ ! -d $PID_DIR ]; then
        mkdir -p $PID_DIR || echo "failed creating PID directory ${PID_DIR}"; exit 1
    fi
    if fun_check_run; then
        echo "${ProgramName} (pid `pidof $NAME`) already running."
        return 0
    fi
    echo -n "Starting ${ProgramName}..."
    fun_check_port
    fun_load_config
    ${BIN} -domain="$dns" -httpAddr=":$http_port" -httpsAddr=":$https_port" -tlsCrt="$srtCRT" -tlsKey="$strKey" -tunnelAddr=":$remote_port"${log_level} > ${LOGFILE} 2>&1 &
    PID=`pidof ${NAME}`
    echo $PID > $PID_FILE
    sleep 0.3
    if ! fun_check_run; then
        echo "start failed"
        return 1
    fi
    echo " done"
    echo "${ProgramName} (pid `pidof $NAME`)is running."
    echo "read ${LOGFILE} for log"
    return 0
}

fun_stop(){
    if [ "${arg1}" = "stop" ] || [ "${arg1}" = "restart" ]; then
      fun_clang_cn
    fi
    if fun_check_run; then
        echo -n "Stoping ${ProgramName} (pid `pidof $NAME`)... "
        kill `pidof $NAME`
        if [ "$?" != 0 ] ; then
            echo " failed"
            exit 1
        else
            echo " done"
            rm -f $PID_FILE
        fi
    else
        echo "${ProgramName} is not running."
    fi
}

fun_restart(){
    fun_stop
    fun_start
}

fun_status(){
    if netstat -tnpl | grep -q ${NAME}; then
        PID=`pidof ${NAME}`
        echo "${ProgramName} (pid $PID) is running..."
        netstat -tnpl | grep "${NAME}"
    else
        echo "${ProgramName} is stopped"
        exit 0
    fi
}
#fun_status && exit 0

# Get version
function getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

checkos(){
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OS=CentOS
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OS=Debian
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OS=Ubuntu
    elif grep -Eqi "Red Hat Enterprise Linux" /etc/issue || grep -Eq "redhat" /etc/*-release; then
        OS=RHEL
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}
#checkos && echo $OS && exit 0

# CentOS version
function check_centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi
}
# Check OS bit
function check_os_bit(){
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
    else
        Is_64bit='n'
    fi
}


function check_killall(){
    killall -V
    #echo $?
    if [[ $? -le 1 ]] ;then
        echo " Run killall success"
    else
        echo " Run killall failed"
        if [ "${OS}" == 'CentOS' ]; then
            echo " Install  centos killall ..."
            #yum -y update
            yum -y install psmisc
        else
            echo " Install  debian/ubuntu killall ..."
            apt-get update -y
            apt-get install -y psmisc
        fi
    fi
    # if [[ ! -d "$result" ]]; then
    # echo "not found"
    # else
    # echo "found"
    # fi
    echo $result
}

check_nano(){
    nano -V
    #echo $?
    if [[ $? -le 1 ]] ;then
        echo " Run nano success"
    else
        echo " Run nano failed"
        checkos
        if [ "${OS}" == 'CentOS' ]; then
            echo " Install  centos nano ..."
            #yum -y update
            yum -y install nano
        else
            echo " Install  debian/ubuntu nano ..."
            #apt-get update -y
            apt-get install -y nano
        fi
    fi
    # if [[ ! -d "$result" ]]; then
        # echo "not found"
    # else
        # echo "found"
    # fi
    echo $result
}
fun_config(){
    check_nano
    if [ -s ${CONFIGFILE} ]; then
        nano ${CONFIGFILE}
    else
        echo "${ProgramName} configuration file not found!"
    fi
}
fun_set_ngrok_username(){
    userName=""
    read -p "Please input UserName for Ngrok(e.g.:ZhangSan):" userName
    check_ngrok_username
}
fun_set_ngrok_subdomain(){
    # Set ngrok pass
    subdomain=""
    ddns=""
    dns=""
    echo "Please input subdomain for Ngrok(e.g.:dns1 dns2 dns3 dns4 dns5):"
    read -p "(subdomain number max five:):" subdomain
    check_ngrok_subdomain
}
fun_set_ngrok_authId(){
    strPass=`fun_randstr`
    echo "Please input the password (more than 8) of Ngrok authId:"
    read -p "(Default password: ${strPass}):" strPassword
    if [ "$strPassword" = "" ]; then
        strPassword=$strPass
    fi
    check_ngrok_authId
}

check_ngrok_username(){
    # check ngrok userName
    if [ "$userName" = "" ]; then
        echo "Your input is empty,please input again..."
        fun_set_ngrok_username
    else
        echo "Your username: ${userName}"
        fun_set_ngrok_subdomain
    fi
}
check_ngrok_subdomain(){
    # check ngrok subdomain
    if [ "$subdomain" = "" ]; then
        echo "Your input is empty, please input again."
        fun_set_ngrok_subdomain
    else
        fun_load_config
        ddns=(${subdomain})
        if [ "$SingleUser" = "y" ] || [ "$SingleUser" = "1" ]; then
            [ -n "${ddns[0]}" ] && subdns=\"${ddns[0]}\"
            [ -n "${ddns[1]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\"
            [ -n "${ddns[2]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\",\"${ddns[2]}\"
            [ -n "${ddns[3]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\",\"${ddns[2]}\",\"${ddns[3]}\"
            [ -n "${ddns[4]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\",\"${ddns[2]}\",\"${ddns[3]}\",\"${ddns[4]}\"
            [ -n "${ddns[0]}" ] && FQDN=\"${ddns[0]}.${dns}\"
            [ -n "${ddns[1]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\"
            [ -n "${ddns[2]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\",\"${ddns[2]}.${dns}\"
            [ -n "${ddns[3]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\",\"${ddns[2]}.${dns}\",\"${ddns[3]}.${dns}\"
            [ -n "${ddns[4]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\",\"${ddns[2]}.${dns}\",\"${ddns[3]}.${dns}\",\"${ddns[4]}.${dns}\"
        else
            [ -n "${ddns[0]}" ] && subdns=\"${ddns[0]}.${userName}\"
            [ -n "${ddns[1]}" ] && subdns=\"${ddns[0]}.${userName}\",\"${ddns[1]}.${userName}\"
            [ -n "${ddns[2]}" ] && subdns=\"${ddns[0]}.${userName}\",\"${ddns[1]}.${userName}\",\"${ddns[2]}.${userName}\"
            [ -n "${ddns[3]}" ] && subdns=\"${ddns[0]}.${userName}\",\"${ddns[1]}.${userName}\",\"${ddns[2]}.${userName}\",\"${ddns[3]}.${userName}\"
            [ -n "${ddns[4]}" ] && subdns=\"${ddns[0]}.${userName}\",\"${ddns[1]}.${userName}\",\"${ddns[2]}.${userName}\",\"${ddns[3]}.${userName}\",\"${ddns[4]}.${userName}\"
            [ -n "${ddns[0]}" ] && FQDN=\"${ddns[0]}.${userName}.${dns}\"
            [ -n "${ddns[1]}" ] && FQDN=\"${ddns[0]}.${userName}.${dns}\",\"${ddns[1]}.${userName}.${dns}\"
            [ -n "${ddns[2]}" ] && FQDN=\"${ddns[0]}.${userName}.${dns}\",\"${ddns[1]}.${userName}.${dns}\",\"${ddns[2]}.${userName}.${dns}\"
            [ -n "${ddns[3]}" ] && FQDN=\"${ddns[0]}.${userName}.${dns}\",\"${ddns[1]}.${userName}.${dns}\",\"${ddns[2]}.${userName}.${dns}\",\"${ddns[3]}.${userName}.${dns}\"
            [ -n "${ddns[4]}" ] && FQDN=\"${ddns[0]}.${userName}.${dns}\",\"${ddns[1]}.${userName}.${dns}\",\"${ddns[2]}.${userName}.${dns}\",\"${ddns[3]}.${userName}.${dns}\",\"${ddns[4]}.${userName}.${dns}\"
        fi
        echo "Your subdomain: ${subdns}"
        fun_set_ngrok_authId
    fi
}
check_ngrok_authId(){
    # check ngrok authId
    if [ "${strPassword}" = "" ]; then
        echo "Your input is empty, please input again..."
        fun_set_ngrok_authId
    else
        echo "Your authId: ${strPassword}"
        fun_adduser_command
    fi
}
fun_adduser_command(){
    fun_load_config
    clear
    fun_clang_cn
    echo  curl -H \"Content-Type: application/json\" -H \"Auth:${pass}\" -X POST -d \''{'\"userId\":\"${strPassword}\",\"authId\":\"${userName}\",\"dns\":[${subdns}]'}'\' http://localhost:${manage_port}/adduser >${str_ngrok_dir}/.ngrok_adduser.sh
    chmod +x ${str_ngrok_dir}/.ngrok_adduser.sh
    . ${str_ngrok_dir}/.ngrok_adduser.sh
    rm -f ${str_ngrok_dir}/.ngrok_adduser.sh
    echo ""
    echo "User list :"
    curl -H "Content-Type: application/json" -H "Auth:${pass}" -X GET http://localhost:${manage_port}/info
    echo "============================================================="
    echo "Server: ${dns}"
    echo "Server  ${remote_port}"
    echo "userId: ${userName}"
    echo "authId: ${strPassword}"
    echo "Subdomain: ${subdns}"
    echo "Your FQDN: ${FQDN}"
    echo "============================================================="
}
fun_adduser(){
    if fun_check_run; then
        fun_load_config
        fun_set_ngrok_username
    else
        echo "${ProgramName} is not running."
    fi
}
fun_deluser(){
    if [ -z "${1}" ]; then
        strWantdeluser=""
        fun_userlist
        echo ""
        read -p "Please input del username you want:" strWantdeluser
        if [ "${strWantdeluser}" = "" ]; then
            echo "Error: You must input username!!"
            exit 1
        else
            deluser_Confirm_clang "${strWantdeluser}"
        fi
    else
        deluser_Confirm_clang "${1}"
    fi
}
deluser_Confirm_clang(){
    if [ -z "${1}" ]; then
        echo "Error: You must input username!!"
        exit 1
    else
        strDelUser="${1}"
        echo "You want del ${strDelUser}!"
        read -p "(if you want please input: y,Default [no]):" strConfirmDel
        case "$strConfirmDel" in
        y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
        echo ""
        strConfirmDel="y"
        ;;
        n|N|No|NO|no|nO)
        echo ""
        strConfirmDel="n"
        ;;
        *)
        echo ""
        strConfirmDel="n"
        esac
        if [ $strConfirmDel = "y" ]; then
            if [ -s "/tmp/db-diskv/ng/ro/ngrok:${strDelUser}" ]; then
                rm -f /tmp/db-diskv/ng/ro/ngrok:${strDelUser}
                echo "Delete user ${strDelUser}　ok! Restart ${NAME}..."
                fun_restart
            else
                echo ""
                echo "Error: user ${strDelUser} not found!"
            fi
        else
            echo "you cancel!"
        fi
    fi
}
fun_userlist(){
    fun_clang_cn
    echo "Ngrok user list:"
    ls /tmp/db-diskv/ng/ro/ |cut -d ':' -f 2
}
fun_info(){
    fun_clang_cn
    if fun_check_run; then
        fun_load_config
        curl -H "Content-Type: application/json" -H "Auth:${pass}" -X GET http://localhost:${manage_port}/info
    else
        echo "${ProgramName} is not running."
    fi
}

function fun_uninstall_ngrok(){
    fun_clang_cn
    if [ -s ${str_ngrok_dir}/bin/ngrokd ] && [ -s /etc/init.d/ngrokd ]; then
        echo "============== Uninstall Ngrok =============="
        save_config="n"
        echo  -e "\033[33mDo you want to keep the configuration file?\033[0m"
        read -p "(if you want please input: y,Default [no]):" save_config
        
        case "${save_config}" in
            y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
                echo ""
                echo "You will keep the configuration file!"
                save_config="y"
            ;;
            n|N|No|NO|no|nO)
                echo ""
                echo "You will NOT to keep the configuration file!"
                save_config="n"
            ;;
            *)
                echo ""
                echo "will NOT to keep the configuration file!"
                save_config="n"
        esac
        checkos
        /etc/init.d/ngrokd stop
        if [ "${OS}" == 'CentOS' ] || [ "${OS}" == 'RHEL' ]; then
            chkconfig --del ngrokd
        else
            update-rc.d -f ngrokd remove
        fi
        rm -f /etc/init.d/ngrokd /usr/bin/ngrokd /var/run/ngrok_clang.pid ${str_ngrok_dir}/ngrok_update.log
        if [ "${save_config}" == 'n' ]; then
            rm -fr ${str_ngrok_dir}
        else
            rm -fr ${str_ngrok_dir}/bin/ ${str_ngrok_dir}/ngrok.log ${str_ngrok_dir}/rootCA.* ${str_ngrok_dir}/server.*
        fi
        echo "Ngrok uninstall success!"
    else
        echo "Ngrok Not install!"
    fi
    echo ""
}

function fun_log(){
    tail $1 /usr/local/ngrok/ngrok.log
}

function fun_update_ngrok(){
    fun_clang_cn
    if [ -s ${str_ngrok_dir}/bin/ngrokd ] && [ -s /etc/init.d/ngrokd ]; then
        echo "============== Update Ngrok =============="
        checkos
        check_centosversion
        check_os_bit
        check_killall
        fun_load_config
        #killall ngrokd
        [ ! -d ${str_ngrok_dir}/bin/ ] && mkdir -p ${str_ngrok_dir}/bin/
        rm -f /usr/bin/ngrokd /var/run/ngrok_clang.pid ${str_ngrok_dir}/ngrok_uninstall.log
        cd ${str_ngrok_dir}
        # Download ngrok file
        if [ "${Is_64bit}" == 'y' ] ; then
            if [ ! -s ${str_ngrok_dir}/bin/ngrokd ]; then
                mv ${str_ngrok_dir}/bin/ngrokd ${str_ngrok_dir}/bin/ngrokd.bak
                if ! wget --no-check-certificate ${str_dir_http_download_root}/ngrok.git/deploy/${dns}/bin/linux_amd64/server/ngrokd -O ${str_ngrok_dir}/bin/ngrokd; then
                    echo "Failed to download ngrokd.x86_64 file!"
                    mv ${str_ngrok_dir}/bin/ngrokd.bak ${str_ngrok_dir}/bin/ngrokd
                    exit 1
                else
                    rm -f ${str_ngrok_dir}/bin/ngrokd.bak
                fi
            fi
        else
            if [ ! -s ${str_ngrok_dir}/bin/ngrokd ]; then
                mv ${str_ngrok_dir}/bin/ngrokd ${str_ngrok_dir}/bin/ngrokd.bak
                if ! wget --no-check-certificate ${str_dir_http_download_root}/ngrok.git/deploy/${dns}/bin/linux_386/server/ngrokd -O ${str_ngrok_dir}/bin/ngrokd; then
                    echo "Failed to download ngrokd.x86 file!"
                    mv ${str_ngrok_dir}/bin/ngrokd.bak ${str_ngrok_dir}/bin/ngrokd
                    exit 1
                else
                    rm -f ${str_ngrok_dir}/bin/ngrokd.bak
                fi
            fi
        fi
        
        [ ! -x ${str_ngrok_dir}/bin/ngrokd ] && chmod 755 ${str_ngrok_dir}/bin/ngrokd
        
        mv /etc/init.d/ngrokd ${str_ngrok_dir}/ngrokd.init.d
        if ! wget --no-check-certificate ${str_dir_http_download_root}/ngrok.git/deploy/ngrokd.init.d -O /etc/init.d/ngrokd; then
            echo "Failed to download ngrokd.init.d file!"
            mv ${str_ngrok_dir}/ngrokd.init.d /etc/init.d/ngrokd
            ln -s /etc/init.d/ngrokd /usr/bin/ngrokd
            exit 1
        else
            rm -rf ${str_ngrok_dir}/ngrokd.init.d
        fi

        [ ! -x /etc/init.d/ngrokd ] && chmod 755 /etc/init.d/ngrokd
        [ -s /etc/init.d/ngrokd ] && ln -s /etc/init.d/ngrokd /usr/bin/ngrokd
        if [ "${OS}" == 'CentOS' ] || [ "${OS}" == 'RHEL' ]; then
            if [ -s /etc/init.d/ngrokd ]; then
                chmod +x /etc/init.d/ngrokd
                chkconfig --add ngrokd
            fi
        else
            if [ -s /etc/init.d/ngrokd ]; then
                chmod +x /etc/init.d/ngrokd
                update-rc.d -f ngrokd defaults
            fi
        fi
        clear
        ngrokd restart
        #/etc/init.d/ngrokd start
        echo "Ngrok update success!"
    else
        echo "Ngrok Not install!"
    fi
    echo ""
}


arg1=$1
arg2=$2
[  -z ${arg1} ]
case "${arg1}" in
    start|stop|restart|status|config|adduser|deluser|userlist|info)
        fun_${arg1} ${arg2}
    ;;
    uninstall)
        fun_uninstall_ngrok 2>&1 | tee ${str_dir_shell}/ngrok_uninstall.log
    ;;
    update)
        fun_update_ngrok 2>&1 | tee ${str_dir_shell}/ngrok_update.log
    ;;
    log)
        fun_log ${arg2} 2>&1 | tee ${str_dir_shell}/ngrok_update.log
    ;;
    *)
        fun_clang_cn
        echo "Usage: $SCRIPTNAME {start|stop|restart|status|config|uninstall|adduser|deluser|userlist|info}"
        RET_VAL=1
    ;;
esac
exit $RET_VAL
