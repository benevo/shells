#!/bin/bash


# default definitions
basepath=$(cd `dirname $0`; pwd)

str_info="\033[45;37m INFO \033[0m "
str_warn="\033[45;37m WARN \033[0m "
str_debug="\033[45;37m DEBUG \033[0m "
str_err="\033[41;37m ERROR: \033[0m "

str_dir_prog="/usr/local/app/apache"
str_file_log="${str_dir_prog}/apache.log"
str_file_conf="${str_dir_prog}/apache.conf"

port_apache_default=8000



function fun_get_apache_dir(){
    if [ -n "$1" ]; then
        if [ -n "$2" ]; then
            port_apache_new="$2"
            apache="$1"
        else
            port_apache_new="8000"
        fi
    else
        port_apache_new="8000"
    fi
}

function fun_debug_input(){
    echo -e "${str_debug} $1 ( $2, $3, $4 )"
}

function fun_apache_pidof_port(){
    if [ -z "$1" ]; then
        ps aux | grep -v "grep" | grep python | awk '{print $2}'
    else
        if [ $1 == ${port_apache_default} ]; then
            ps aux | grep -v "grep" | grep "python -m SimpleHTTPServer\|python -mSimpleHTTPServer" | awk '{print $2, $NF}' | grep "HTTP\|${port_apache_default}" | awk '{print $1}'
        else
            ps aux | grep -v "grep" | grep "python -m SimpleHTTPServer $1\|python -m SimpleHTTPServer $1" | awk '{print $2}'
        fi 
    fi
}

function fun_apache_config(){
    # fun_debug_input "${FUNCNAME}" $@

    vi ${str_file_conf}

}

function fun_apache_status(){
    list=`ps aux | grep "python -m SimpleHTTPServer" | grep -v "grep" | awk '{print $2, "\t"$NF, "\t"$1}' | wc -l`
    if [ "$list" -gt 0 ]; then
        echo -e "\033[33mPID\tPORT\tUSER\tDirectory \033[0m"
        echo "----------------------------------"
        ps aux | grep "python -m SimpleHTTPServer" | grep -v "grep" | awk '{print $2, "\t"$NF, "\t"$1}'
    fi
}

function fun_apache_start_port(){
    # Description: for python -mSimpleHTTPServer
    # one port must has only one dir server
    # one dir server can has one or more port

    # fun_debug_input "${FUNCNAME}" $@

    [ $# != 2 ] && return 0

    local str_dir_root=${1/\~/`echo ~`} # if dir contain char '~', then [ -d "dir" ] cannot detect whether dir existed...
    [ "${str_dir_root}" == "default" ] && {
        # if is default root dir & not exist, create it 
        str_dir_root="${APACHE_WEB_HOME}"
        # str_dir_root="~/web/apache/test"
        [ -z "${str_dir_root}" ] && {
            echo "defautl apache dir not set."
            return 0
        }
        str_dir_root=${str_dir_root/\~/`echo ~`} 
        [ ! -d ${str_dir_root} ] && mkdir -p ${str_dir_root}
    }

    [ ! -d "${str_dir_root}" ] && {
        echo -e "${str_warn} Failed to start [ $* ]: Directory is not available."
        return 0
    }

    [ $2 -lt ${port_apache_default} ] && {
        # check port, must be equal to or greater than default
        echo -e "${str_warn} Failed to start [ ${str_dir_root} $2 ]: Port number is smaller than default ${port_apache_default}."
        return 0
    }
    
    local pid=`fun_apache_pidof_port "$2"`
    [ -n "$pid" ] && {
        echo "Port $2 is busy on PID ${pid}, try another one."
        return 0
    }

    cd ${str_dir_root}
    nohup python -m SimpleHTTPServer ${2} &> ${str_file_log} &
    sleep 0.3
    pid=`fun_apache_pidof_port "$2"`
    echo -e "${str_info} Apache server for directory: \033[36m "${str_dir_root}" \033[0m  \033[32m started: \033[0m"
    echo -e "\tPort: \033[36m ${2} \033[0m"
    echo -e "\tPID: \033[36m ${pid} \033[0m"

    return 0
}

function fun_apache_start(){
    # web server for local directory ${str_dir_log_apache}

    # fun_debug_input "${FUNCNAME}" $@

    # [ -z "$1" ] && {
    #     fun_apache_start_port "default" ${port_apache_default}
    #     return 0
    # }

    [ "$1" == "${port_apache_default}" ] && {
        fun_apache_start_port "default" ${port_apache_default}
        return 0
    }

    local path_conf="$1"
    if [ -z "$1" ]; then
        path_conf="${str_file_conf}"
    fi

    if [ ! -f "${path_conf}" ]; then
        echo -e "${str_info} File: ${path_conf} not existed!"
        return 0
    fi
    
    cat ${path_conf} | while read line
    do
        # echo ${line}
        if [ -n "${line}" ]; then
            if ! [[ ${line} =~ ^# ]]; then
                fun_apache_start_port ${line}
            fi
        fi
    done
}

function fun_apache_stop(){
    #fun_debug_input "${FUNCNAME}" $@
    
    local pid

    if [ -n "$1" ]; then
        pid=`fun_apache_pidof_port "$1"`
        if [ -n "${pid}" ]; then
            kill ${pid}
            sleep 0.1
            echo -e "Apache service on Port $1 stopped."
            return 0
        else
            echo -e "No apache service found on Port: $1"
            return 0
        fi
    fi
    
    pid=`fun_apache_pidof_port`
    if [ -z "${pid}" ]; then
        echo -e "No apache server found."
        return 0
    fi
    
    kill ${pid}
    # sed '/^'$pid_apache_found'/d' ${basepath}/.apache.db > .apache.db	# 删除记录
    echo -e "${str_info} Apache service all stoped."
}

function fun_apache_restart(){
    fun_apache_stop
    fun_apache_start
    fun_apache_status
    echo ""
    echo -e "Apache services restarted."
}

# main

#clear
action=$1
[  -z $1 ]
case "$action" in
    start-port) # apache start-port /root/document 8290
        rm -f ${str_file_log}
        fun_get_apache_dir "$2" "$3"
        fun_apache_start $apache $port_apache_new 2>&1 | tee ${str_file_log}
    ;;
    stop-port) # apache stop 8000
        fun_apache_stop "$2"
    ;;
    start) # apache startf /path/for/cfgfile
        rm -f ${str_file_log}
        fun_apache_start "$2" 2>&1 | tee ${str_file_log}
    ;;
    stop)
        fun_apache_stop "$2" 2>&1 | tee ${str_file_log}
    ;;
    restart)
        fun_apache_restart
    ;;
    status)
        fun_apache_status
    ;;
    config) # apache startf /path/for/cfgfile
        fun_apache_config
    ;;
    *)
        echo "Arguments error! [ ${action} ]"
        echo "Usage: $0 [ start | stop | restart | status | config ]"
    ;;
esac
