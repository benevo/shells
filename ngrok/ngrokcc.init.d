#!/bin/bash
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
NAME=ngrok
SCRIPTNAME=/etc/init.d/${NAME}

str_dir_prog="/usr/local/ngrok"
str_dir_shell=$(cd `dirname $0`; pwd)
str_dir_http_download_root="http://benevo.ngrok.cc"
str_name_ddns=""
str_logfile=${str_dir_prog}/ngrok.log

PID_DIR=/var/run
PID_FILE=$PID_DIR/ngrok_clang.pid
version="v5.6"
manage_port="4446"
RET_VAL=0

if [ -n "$2" ]; then
    str_name_ddns=$2
fi

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


function fun_debug_input(){
    echo -e "${str_debug} $1 ( $2, $3, $4 )"
}

function fun_str_dir_update(){
    [ -n "$1" ] && str_name_ddns=$1
    [ -z "${str_name_ddns}" ] && {
        echo "Please check input ddns name !"
        return 0
    }
    str_dir_ddns="${str_dir_prog}/${str_name_ddns}"
    str_dir_file_ngrok="${str_dir_ddns}/bin"
    str_file_ngrok="${str_dir_ddns}/bin/${NAME}"
    str_file_ddns_conf=${str_dir_ddns}/.ngrok.conf

    [ -d "${str_dir_ddns}" ] && bool_dir_ngrok=1 || bool_dir_ngrok=0
    [ -s "${str_file_ngrok}" ] && bool_file_ngrok=1 || bool_file_ngrok=0
    [ -s "${str_file_ddns_conf}" ] && bool_file_ddns_conf=1 || bool_file_ddns_conf=0
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
    if [ ! -r ${str_file_ddns_conf} ]; then
        echo "config file ${str_file_ddns_conf} not found"
        return 1
    else
        . ${str_file_ddns_conf}
        log_level=""
        [ -n "${loglevel}" ] && log_level=" -log-level=\"${loglevel}\""
        cd ${str_dir_prog}
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

# 返回某个DDNS运行实例个数
fun_check_run_ddns() {
    # fun_debug_input "${FUNCNAME}" $@
    ps aux | grep "/.ngrok.conf start" | grep -v "grep" | grep "$str_name_ddns" | grep "ngrok" | awk '{print $2}'
}

fun_start()
{    
    if [ -z "${1}" ]; then
        local str_name_ddns_to_start=""
        fun_list
        read -p "Please input ddns name you want to start:" str_name_ddns_to_start
        if [ "${str_name_ddns_to_start}" = "" ]; then
            echo "Error: You must input a ddns name!!"
            exit 1
        fi
    else
        str_name_ddns_to_start=$1
    fi
    fun_str_dir_update $str_name_ddns_to_start

    if [ "$bool_file_ngrok" == "0" ]; then
        echo "ddns $str_name_ddns_to_start not added yet !"
        exit 0
    fi

    if [ ! -d $PID_DIR ]; then
        mkdir -p $PID_DIR || echo "failed creating PID directory ${PID_DIR}"; exit 1
    fi

    if [ `fun_check_run_ddns` -gt 0 ]; then
        echo "${ProgramName} (pid `pidof $NAME`) already running."
        return 0
    fi

    echo -n "Starting ${ProgramName}..."
    # fun_check_port
    # fun_load_config
    ${str_file_ngrok} -config=${str_file_ddns_conf} start benevo #> ${str_logfile} 2>&1 &

    PID=`pidof ${NAME}`
    echo $PID > $PID_FILE
    sleep 0.3    
    return 0
    if ! fun_check_run; then
        echo "start failed"
        return 1
    fi
    echo " done"
    echo "${ProgramName} (pid `pidof $NAME`)is running."
    echo "read ${str_logfile} for log"
    return 0
}

fun_stop(){
    local str_name_ddns_to_stop=""
    if [ -z "${1}" ]; then
        fun_list
        read -p "Please input ddns name you want to stop:" str_name_ddns_to_stop
        if [ "${str_name_ddns_to_stop}" = "" ]; then
            echo "Error: You must input a ddns name!!"
            exit 1
        fi
    else
        str_name_ddns_to_stop=$1
    fi
    fun_str_dir_update $str_name_ddns_to_stop

    if [ "$bool_file_ngrok" == "0" ]; then
        echo "ddns $str_name_ddns_to_stop not exists !"
        exit 0
    fi

    local pid_ddns=`fun_check_run_ddns $str_name_ddns_to_stop`
    if [ -n "${pid_ddns}" ]; then
        echo -n "Stoping ${str_name_ddns_to_stop} (pid ${pid_ddns})... "
        kill ${pid_ddns}
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

fun_stop-all(){
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
    ps aux | grep "/.ngrok.conf start" | grep -v "grep" | grep "$str_name_ddns" | grep "ngrok" | awk '{print $2, $11}' | awk -F"/" '{print $1, $5}'
    return 0
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
    echo  curl -H \"Content-Type: application/json\" -H \"Auth:${pass}\" -X POST -d \''{'\"userId\":\"${strPassword}\",\"authId\":\"${userName}\",\"dns\":[${subdns}]'}'\' http://localhost:${manage_port}/adduser >${str_dir_prog}/.ngrok_adduser.sh
    chmod +x ${str_dir_prog}/.ngrok_adduser.sh
    . ${str_dir_prog}/.ngrok_adduser.sh
    rm -f ${str_dir_prog}/.ngrok_adduser.sh
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

function checkos(){
    OS_CORE=`uname`
    
    if [ "$OS_CORE" == "Linux" ]; then
        if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
            OS=CentOS
        elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
            OS=Debian
        elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
            OS=Ubuntu
        elif grep -Eqi "Red Hat Enterprise Linux" /etc/issue || grep -Eq "redhat" /etc/*-release; then
            OS=RHEL
        else
            echo "Not support Linux OS type, Please reinstall OS and retry!"
            exit 1
        fi
    elif [ "$OS_CORE" == "Darwin" ]; then
        OS="${OS_CORE}"
        echo "Checked OS Type: $OS"
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}


fun_config(){
    if [ -z "${1}" ]; then
        local str_to_config_ddns_name=""
        fun_list
        read -p "Please input ddns name you want to config:" str_to_config_ddns_name
        if [ "${str_to_config_ddns_name}" = "" ]; then
            echo "Error: You must input a ddns name!!"
            exit 1
        fi
    else
        str_to_config_ddns_name=$1
    fi

    fun_str_dir_update $str_to_config_ddns_name
    if [ -s ${str_file_ddns_conf} ]; then
        vi ${str_file_ddns_conf}
    else
        echo "${ProgramName} configuration file for this ddns not found!"
    fi
}


fun_add(){
    if [ -z "${1}" ]; then
        local str_to_add_ddns_name=""
        fun_list
        read -p "Please input ddns name you want to add:" str_to_add_ddns_name
        if [ "${str_to_add_ddns_name}" = "" ]; then
            echo "Error: You must input a ddns name!!"
            exit 1
        fi
    else
        str_to_add_ddns_name=$1
    fi

    echo "Installing ngrok ddns ${str_to_add_ddns_name}, please wait..."
    echo "============== Downloading client =============="
    fun_str_dir_update ${str_to_add_ddns_name}

    
    # Download ngrok file

    checkos
    check_centosversion
    check_os_bit
    local str_ngrok_ver
    if [ "${Is_64bit}" == 'y' ] ; then
        str_ngrok_ver="amd64"
    else
        str_ngrok_ver="386"
    fi
    if [ "${OS_CORE}" == 'Linux' ] ; then
        str_ngrok_ver="linux_${str_ngrok_ver}"
    elif [ "${OS_CORE}" == 'Darwin' ]; then
        str_ngrok_ver="darwin_${str_ngrok_ver}"
    else
        str_ngrok_ver="windows_${str_ngrok_ver}.exe"
    fi
    
    if [ ! -s ${str_file_ngrok} ]; then
        if ! wget --spider ${str_dir_http_download_root}/deploy/${str_name_ddns}/${str_ngrok_ver}/client/ngrok; then
            exit 0
        fi

        [ ! -d "$str_dir_file_ngrok" ] && mkdir -p ${str_dir_file_ngrok}
        if ! wget ${str_dir_http_download_root}/deploy/${str_name_ddns}/${str_ngrok_ver}/client/ngrok -O ${str_file_ngrok}; then
            echo "Failed to download ngrok file!"
            exit 1
        fi
    fi
    
    if [ -s ${str_file_ngrok} ]; then
        [ ! -x ${str_file_ngrok} ] && chmod 755 ${str_file_ngrok}
        clear
        config_runshell_ngrok

        echo "------------"
        echo ""
        echo -e "New ddns instance :\033[32m\033[01m ${str_name_ddns} \033[0m added ."
        echo ""
        exit 0
    else
        echo ""
        echo "Sorry,Failed to install Ngrok!"
        echo "You can download ${str_dir_shell}/ngrok-install.log from your server,and mail ngrok-install.log to me."
        exit 1
    fi
    
    shell_run_end=`date "+%Y-%m-%d %H:%M:%S"`   #shell run end time
    time_distance=$(expr $(date +%s -d "$shell_run_end") - $(date +%s -d "$shell_run_start"));
    hour_distance=$(expr ${time_distance} / 3600) ;
    hour_remainder=$(expr ${time_distance} % 3600) ;
    min_distance=$(expr ${hour_remainder} / 60) ;
    min_remainder=$(expr ${hour_remainder} % 60) ;
    echo -e "Shell run time is \033[32m \033[01m${hour_distance} hour ${min_distance} min ${min_remainder} sec\033[0m"
}

function config_runshell_ngrok(){
cat > ${str_file_ddns_conf} <<EOF
server_addr: "${str_name_ddns}:4443"
trust_host_root_certs: false
#auth_token: "85279ddea86ece34c473ed52d079fc77"
tunnels:
  test:
   subdomain: "test" #定义服务器分配域名前缀，跟平台上的要一样
   proto:
    http: 19870 #映射端口，不加ip默认本机
    https: 80
EOF
    chmod 750 ${str_file_ddns_conf}
    
    if [ -s /etc/init.d/ngrok ]; then
        if ! wget --no-check-certificate ${str_dir_http_download_root}/ngrok.init.d -O /etc/init.d/ngrok; then
            echo "Failed to download ngrok.init.d file!"
            exit 1
        fi
    fi
    [ ! -x /etc/init.d/ngrok ] && chmod 755 /etc/init.d/ngrok
    [ ! -x ${str_file_ddns_conf} ] && chmod 500 ${str_file_ddns_conf}
    if [ "${OS}" == 'CentOS' ] || [ "${OS}" == 'RHEL' ]; then
        if [ -s /etc/init.d/ngrok ]; then
            chmod +x /etc/init.d/ngrok
            chkconfig --add ngrok
        fi
    else
        if [ -s /etc/init.d/ngrok ]; then
            chmod +x /etc/init.d/ngrok
            update-rc.d -f ngrokd defaults
            sed -i 's/#TMPTIME=.*/TMPTIME=-1/' /etc/default/rcS
            sed -i 's/TMPTIME=.*/TMPTIME=-1/' /etc/default/rcS
        fi
    fi
    [ -s /etc/init.d/ngrok ] && ln -s /etc/init.d/ngrok /usr/bin/ngrok
}

fun_del(){
    if [ -z "${1}" ]; then
        local str_to_del_ddns_name=""
        fun_list
        echo ""
        read -p "Please input ddns name you want to del:" str_to_del_ddns_name
        if [ "${str_to_del_ddns_name}" = "" ]; then
            echo "Error: You must input a ddns name!!"
            exit 1
        else
            del_confirm_ddns "$str_to_del_ddns_name" "$2"
        fi
    else
        del_confirm_ddns "${1}" "$2"
    fi
}

fun_del-all(){
    if [ "$1" == "y" ]; then
        strConfirmDel="y"
    else
        echo "You want del all ddns !"
        read -p "(if you want, please input: [ Y ], Default [ N ]): " strConfirmDel
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
    fi
    if [ $strConfirmDel = "y" ]; then
        ls ${str_dir_prog} | awk '{print $INF}' | while read line
        do
            fun_del $line "y"
        done
    else
        echo "you canceled !"
    fi
}

function del_confirm_ddns(){
    if [ -z "${1}" ]; then
        echo "Error: You must input username!!"
        exit 1
    else
        local str_del_ddns_name="${1}"
        if [ "${2}" == "y" ]; then
            strConfirmDel="y"
        else
            echo "You want del ${str_del_ddns_name}!"
            read -p "(if you want, please input: [ Y ], Default [ N ]): " strConfirmDel
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
        fi

        if [ $strConfirmDel = "y" ]; then
            echo ${str_del_ddns_name}
            if [ -z "${str_del_ddns_name}" ]; then
                return 0
            fi
            if [ -d "${str_dir_prog}/${str_del_ddns_name}" ]; then
                /etc/init.d/ngrok stop $str_del_ddns_name
                rm -rf ${str_dir_prog}/${str_del_ddns_name}
                echo "Delete ddns ${str_del_ddns_name}　ok! "
                echo ""
            else
                echo ""
                echo "Error: ddns ${str_del_ddns_name} not found!"
                echo ""
            fi
        else
            echo "you canceled !"
        fi
    fi
}

fun_list(){
    fun_clang_cn
    echo "Ngrok ddns installed list:"
    echo "-----------------"
    ls ${str_dir_prog} | awk '{print $INF}'
    echo ""
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
    if [ -s /etc/init.d/ngrok ]; then
        echo "============== Uninstall Ngrok =============="
        save_config="n"
        echo  -e "\033[33mDo you want to keep the ddns instance?\033[0m"
        read -p "(if you want please input: y,Default [no]):" save_config
        
        case "${save_config}" in
            y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
                echo ""
                echo "You will keep the ddns instance!"
                save_config="y"
            ;;
            n|N|No|NO|no|nO)
                echo ""
                echo "You will NOT to keep the ddns instance!"
                save_config="n"
            ;;
            *)
                echo ""
                echo "will NOT to keep the ddns instance!"
                save_config="n"
        esac
        checkos
        fun_stop-all
        fun_del-all "y"
        if [ "${OS}" == 'CentOS' ] || [ "${OS}" == 'RHEL' ]; then
            chkconfig --del ngrok
        else
            update-rc.d -f ngrokd remove
        fi
        rm -f /etc/init.d/ngrok /usr/bin/ngrok /var/run/ngrok_clang.pid ${str_dir_prog}/ngrok_update.log
        if [ "${save_config}" == 'n' ]; then
            rm -fr ${str_dir_prog}
        else
            rm -fr ${str_dir_prog}/bin/ ${str_dir_prog}/ngrok.log ${str_dir_prog}/rootCA.* ${str_dir_prog}/server.*
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
    if [ -s ${str_dir_prog}/bin/ngrokd ] && [ -s /etc/init.d/ngrokd ]; then
        echo "============== Update Ngrok =============="
        checkos
        check_centosversion
        check_os_bit
        check_killall
        fun_load_config
        #killall ngrokd
        [ ! -d ${str_dir_prog}/bin/ ] && mkdir -p ${str_dir_prog}/bin/
        rm -f /usr/bin/ngrokd /var/run/ngrok_clang.pid ${str_dir_prog}/ngrok_uninstall.log
        cd ${str_dir_prog}
        # Download ngrok file
        if [ "${Is_64bit}" == 'y' ] ; then
            if [ ! -s ${str_dir_prog}/bin/ngrokd ]; then
                mv ${str_dir_prog}/bin/ngrokd ${str_dir_prog}/bin/ngrokd.bak
                if ! wget --no-check-certificate ${str_dir_http_download_root}/ngrok.git/deploy/${dns}/bin/linux_amd64/server/ngrokd -O ${str_dir_prog}/bin/ngrokd; then
                    echo "Failed to download ngrokd.x86_64 file!"
                    mv ${str_dir_prog}/bin/ngrokd.bak ${str_dir_prog}/bin/ngrokd
                    exit 1
                else
                    rm -f ${str_dir_prog}/bin/ngrokd.bak
                fi
            fi
        else
            if [ ! -s ${str_dir_prog}/bin/ngrokd ]; then
                mv ${str_dir_prog}/bin/ngrokd ${str_dir_prog}/bin/ngrokd.bak
                if ! wget --no-check-certificate ${str_dir_http_download_root}/ngrok.git/deploy/${dns}/bin/linux_386/server/ngrokd -O ${str_dir_prog}/bin/ngrokd; then
                    echo "Failed to download ngrokd.x86 file!"
                    mv ${str_dir_prog}/bin/ngrokd.bak ${str_dir_prog}/bin/ngrokd
                    exit 1
                else
                    rm -f ${str_dir_prog}/bin/ngrokd.bak
                fi
            fi
        fi
        
        [ ! -x ${str_dir_prog}/bin/ngrokd ] && chmod 755 ${str_dir_prog}/bin/ngrokd
        
        mv /etc/init.d/ngrokd ${str_dir_prog}/ngrokd.init.d
        if ! wget --no-check-certificate ${str_dir_http_download_root}/ngrok.git/deploy/ngrokd.init.d -O /etc/init.d/ngrokd; then
            echo "Failed to download ngrokd.init.d file!"
            mv ${str_dir_prog}/ngrokd.init.d /etc/init.d/ngrokd
            ln -s /etc/init.d/ngrokd /usr/bin/ngrokd
            exit 1
        else
            rm -rf ${str_dir_prog}/ngrokd.init.d
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
    start|stop|restart|config|status|add|del|del-all|list|info)
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
        echo "Usage: $SCRIPTNAME {start|stop|restart|status|config|uninstall|add|del|del-all|list|info}"
        RET_VAL=1
    ;;
esac
exit $RET_VAL
