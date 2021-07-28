#!/bin/bash

###################################################################################################
#
# Script:       podman.opensuse-tumbleweed-rmt-server.sh
#
# Description:  Script run RMT Server on containerized OpenSUSE Tumbleweed
#
# Author:       thomas.rudolph@gmail.com
#
# Url:          https://github.com/t-ru/container-images
#
# Version:      2021-07-27
#
# History:      2021-07-27      -   initial version
#
###################################################################################################


###################################################################################################
# Global Variables
###################################################################################################


###################################################################################################
# Functions
###################################################################################################

#--------------------------------------------------------------------------------------------------
# FUNCTION: is_root_user()
#   -   root user check
#   -   Return
#           -   is root: return "1"
#           -   is not root: return ""
function is_root_user()
{
    local _result=""

    # user is root: 1
    # user is not root: ""
    _result=$( [ $(id -u) -eq 0 ] && echo "1" || echo "" )

    # echo silent (result will not printed to stdout)
    [[ $( echo $_result ) ]]
}

#--------------------------------------------------------------------------------------------------
# FUNCTION: trim()
#   -   trims whitespace from left and right side of supplied string
#   -   Arguments
#           - $1: string to trim
function trim() 
{
    local _value="${1}"

    #_result=$( echo -n "$1" | xargs )
    _value=$( echo -n "$_value" | sed -e 's/^ *//g' -e 's/ *$//g' )
    
    echo -n "${_value}"
}

#--------------------------------------------------------------------------------------------------
# FUNCTION: strip_quotes()
#   -   remove surrounding quotes (both single and double) while keeping 
#       quoting characters inside the string intact
#   -   Arguments
#           - $1: string to strip
function strip_quotes()
{
    local _value="${1}"

    [[ "${_value}" == \"*\" || "${_value}" == \'*\' ]] && _value="${_value:1:-1}"

    echo -n "${_value}"
}


#--------------------------------------------------------------------------------------------------
# FUNCTION: to_upper()
#   -   converts a string to upper case
#   -   Arguments
#           - $1: string to convert
function to_upper()
{
    local _value="${1}"

    _value=$( echo -n "$_value" | tr  "[:lower:]" "[:upper:]" )

    echo -n "${_value}"
}

#--------------------------------------------------------------------------------------------------
# FUNCTION: to_lower()
#   -   converts a string to lower case
#   -   Arguments
#           - $1: string to convert
function to_lower()
{
    local _value="${1}"

    _value=$( echo -n "$_value" | tr "[:upper:]" "[:lower:]" )

    echo -n "${_value}"
}

#--------------------------------------------------------------------------------------------------
# FUNCTION: is_empty()
#   -   Checks if a variable is set (not null) and has a value.
#   -   Arguments
#           - $1: Variable passed to check
#           - $2: Strict Mode (optional) 
#                 will return true if the value exists but is zero
#                 true (default) | false
#   -   Return
#           -   empty: return "1"
#           -   not empty: return ""
function is_empty()
{
    local _var="${1}"
    local _strict_mode="true"
    local _result=""

    if [  $# -eq 2 ] ; then
        if [ "${2}" == "false" ] ; then _strict_mode="false" ; fi 
    fi

    if [ "${_strict_mode}" == "true" ] ; then
        # strict mode = on
        if [ -z "${_var}" ] ; then
            _result="1"
        elif [ "${_var}" == 0 2> /dev/null ] ; then
            _result="1"
        elif [ "${_var}" == 0.0 2> /dev/null ] ; then
            _result="1"
        fi
    else
        # strict mode = off
        if [ -z "${_var}" ] ; then
           _result="1"
        fi
    fi

    # echo silent (result will not printed to stdout)
    [[ $( echo $_result ) ]]
}


#--------------------------------------------------------------------------------------------------
# FUNCTION: config_file___get_value()
#   -   Loads key value from file
#   -   Arguments
#           - $1: File
#           - $2: Key name
function config_file___get_value()
{
    local _file="${1}"
    local _key="${2}"
    local _error="false"
    local _result="" 

    if (is_empty "${_key}") ; then _error="true" ; fi
    if (is_empty "${_file}") ; then _error="true" ; fi
    if [ ! -f "${_file}" ] ; then _error="true" ; fi
    
    if [ "${_error}" == "false" ] ; then

        # get line by "key" and split by "key="
        _result=$( cat "${_file}" 2>/dev/null | grep "^${_key}" | awk -F "${_key}=" '{print $2}' )  
        
        _result=$( trim "$_result" )

        _result=$( strip_quotes "$_result" ) 

    fi

    echo -n "${_result}"
}

#--------------------------------------------------------------------------------------------------
# FUNCTION: console___write()
#   -   Write arguments to the standard output
#   -   Arguments
#           $1                      Message
#           --black                 optional | black terminal output
#           --red                   optional | red terminal output
#           --green                 optional | green terminal output
#           --yellow                optional | yellow terminal output
#           --blue                  optional | blue terminal output
#           --magenta               optional | magenta terminal output
#           --cyan                  optional | cyan terminal output
#           --white                 optional | white terminal output
#           --bold                  optional | bold terminal output
#           --no-newline    -n      optional | no linebreak / no newline on output
#   -   Usage
#           msg "string" [optional args]
#           msg "foo" --cyan
#           msg "foo" --cyan --bold
#           msg "foo" --cyan --no-newline
function console___write()
{
    if [[ "$#" -eq 0 ]] ; then

        echo ""

    else

        # https://linuxcommand.org/lc3_adv_tput.php
        # https://riptutorial.com/bash/example/19531/a-function-that-accepts-named-parameters
        
        local _message="${1}"
        local _newline="true"
            
        if [[ "$#" -gt 0 ]] ; then

            while [[ "$#" -gt 0 ]]
            do
            
                case ${1^^} in
                    --BLACK)                tput setaf 0 ;;
                    --RED)                  tput setaf 1 ;;
                    --GREEN)                tput setaf 2 ;;
                    --YELLOW)               tput setaf 3 ;;
                    --BLUE)                 tput setaf 4 ;;
                    --MAGENTA)              tput setaf 5 ;;
                    --CYAN)                 tput setaf 6 ;;
                    --WHITE)                tput setaf 7 ;;
                    --BOLD)                 tput bold ;;
                    --NO-NEWLINE | -N)      _newline="false" ;;
                esac

                shift

            done

        fi

        if [ "${_newline}" == "true" ] ; then
            echo "${_message}"
        else
            echo -n "${_message}"
        fi

        # reset
        tput sgr0

    fi
}

function console___set_cursor_to_column()
{
    local col=${1}
    #col=$(($col-1))
    #if [ ${col} -eq 0 ] ; then col=-1; fi
    [ "${col}" -eq 1 ] && col=-1 || col=$((col-1))

    echo -ne "\033[50D\033[${col}C"

}

#--------------------------------------------------------------------------------------------------
# FUNCTION: script_header___get_string()
#   - Returns Header string information from comments of file
#   - This keys off of the '# <header_identifier>: ' comment line found at the top of the scripts
#   - Arguments
#       - $1: Identifier
#       - $2: File to inspect
function script_header___get_string() 
{
    local _identifier="${1}"
    local _file="${2}"
    local _result=""
    
    _result="$( \
        cat "${_file}" 2>/dev/null | \
        grep "^# ${_identifier}:" | \
        sed -e 's/[[:space:]]\+/ /g' | \
        awk -F"# ${_identifier}:" '{print $2}' | \
        sed -e 's/^ *//g' -e 's/ *$//g' | \
        sed -e 's/^ *//g' -e 's/ *$//g' \
        )"
    
    echo -n "${_result}"
}

function script_header___get_version() 
{
    local _file="${1}"
    local _result=$( script_header___get_string "Version" "${script_file_full}" )
    echo -n "${_result}"
}

function script_header___get_description() 
{
    local _file="${1}"
    local _result=$( script_header___get_string "Description" "${script_file_full}" )
    echo -n "${_result}"
}

function script_header___get_author() 
{
    local _file="${1}"
    local _result=$( script_header___get_string "Author" "${script_file_full}" )
    echo -n "${_result}"
}

function script_header___get_url() 
{
    local _file="${1}"
    local _result=$( script_header___get_string "Url" "${script_file_full}" )
    echo -n "${_result}"
}

function script_header___get_script() 
{
    local _file="${1}"
    local _result=$( script_header___get_string "Script" "${script_file_full}" )
    echo -n "${_result}"
}

#--------------------------------------------------------------------------------------------------
# FUNCTION: version()
#   -   show version of script
function version ()
{
    echo ""
    echo "$( script_header___get_script '${script_file_full}' )"
    echo ""
    echo "Version $( script_header___get_version '${script_file_full}' )"
    echo ""
}

#--------------------------------------------------------------------------------------------------
# FUNCTION: usage()
#   -   show usage of script
function usage()
{

    echo ""
    echo "---- Usage ----"
    echo ""
    #echo "    as root user:                 ${0} <command> [--command-options]"
    #echo "    with sudo:                    sudo ${0} <command> [--command-options]"
    echo "    as root user:                 ${0} <options>"
    echo "    with sudo:                    sudo ${0} <options>"
    
    echo ""
    echo "---- Options ----"
    echo ""
    echo "    --start                         start container"
    echo "    --stop                          stop container"
    echo "    --login                         login to container"
    
    echo "    --version                       display version information and exit"
    echo "    --help                          display this help and exit"

    echo ""
    echo "---- Info ----"
    echo ""
    echo "    Script:                       $( script_header___get_script '${script_file_full}' )"
    echo "    Description:                  $( script_header___get_description '${script_file_full}' )"
    echo "    Author:                       $( script_header___get_author '${script_file_full}' )"
    echo "    Url:                          $( script_header___get_url '${script_file_full}' )"
    echo "    Version:                      $( script_header___get_version '${script_file_full}' )"

    echo ""

}


function container___init()
{

    #### script info
    echo ""
    echo "---- Info ----"
    echo ""
    echo "Script:                       $( script_header___get_script '${script_file_full}' )"
    echo "Description:                  $( script_header___get_description '${script_file_full}' )"
    echo "Author:                       $( script_header___get_author '${script_file_full}' )"
    echo "Url:                          $( script_header___get_url '${script_file_full}' )"
    echo "Version:                      $( script_header___get_version '${script_file_full}' )"
    echo ""

    #### check binaries
    echo "---- Check binaries ----"

    declare -a files=( "/usr/bin/podman" "/usr/bin/certstrap" )
    required_packages="podman certstrap"
    missing="false"

    for (( i=1; i <= ${#files[@]}; i++ )) ; do

        [[ "${i}" -eq 1 ]] && echo ""

        console___write "[ CHECK  ] ${files[$(($i-1))]}" --no-newline
        console___set_cursor_to_column 1
        sleep 1
        
        if [[ -e "${files[$(($i-1))]}" ]] ; then
            console___write "[ OK     ]" 
        else
            #echo "${files[$(($i-1))]} : not found"
            console___write "[ FAILED ]"
            missing="true"
        fi 
    done

    if [ "${missing}" == "true" ] ; then
        
        echo ""
        echo "---- Script aborted ----"
        echo ""
        echo "Binaries missing. Please install required packages."
        echo ""
        echo "Required packages: $required_packages"
        echo ""
        echo "Exit Code: 2"
        echo ""
        exit 2

    fi

}

function container___start ()
{
    
    local _container_image=""
    local _container_name=""

    local _rmt_scc_user=""
    local _rmt_scc_pw=""

    local _hostname=$( hostname )
    local _port_http="80"
    local _port_https="443"
    
    console___write ""
    console___write "---- Configuration ----"
    console___write ""
   
    _container_image=$( config_file___get_value "${config_file_full}" "container_image" )
    _container_name=$( config_file___get_value "${config_file_full}" "container_name" )
    _container_base_path=$( config_file___get_value "${config_file_full}" "container_base_path" )

    _scc_username=$( config_file___get_value "${config_file_full}" "scc_username" )
    _scc_password=$( config_file___get_value "${config_file_full}" "scc_password" )

    _path_db="${_container_base_path}/mariadb"
    _path_certs="${_container_base_path}/certs"
    _path_storage="${_container_base_path}/storage"

    console___write "Config File ...........................: ${config_file_full}"
    console___write ""
    console___write "Container Image .......................: ${_container_image}"
    console___write "Container Name ........................: ${_container_name}"
    console___write "Container Base Path ...................: ${_container_base_path}"
    console___write ""
    console___write "SCC Username ..........................: ${_scc_username}"
    console___write "SCC Password ..........................: ${_scc_password}"
    console___write ""
    console___write "Hostname ..............................: ${_hostname}"
    console___write "Port (HTTP) ...........................: ${_port_http}"
    console___write "Port (HTTPS) ..........................: ${_port_https}"

    console___write ""
    console___write "Repo URL (HTTP) .......................: http://${_hostname}/repo"
    console___write "Repo URL (HTTPS) ......................: https://${_hostname}/repo"
       
    
    
    console___write ""
    console___write "---- Create Directories (if required) ----"
    console___write ""
        
    mkdir -p ${_container_base_path}/var/lib/mysql
    mkdir -p ${_container_base_path}/var/lib/rmt
    mkdir -p ${_container_base_path}/etc/rmt/ssl

    console___write "Done."



    console___write ""
    console___write "---- Create SSL Certificates (if required) ----"
    console___write ""


    if [ ! -e ${_container_base_path}/etc/rmt/ssl/rmt-ca.crt ]; then
        echo "rmt-ca.crt not found."
	    certstrap --depot-path ${_container_base_path}/etc/rmt/ssl/ init --common-name "rmt-ca" --passphrase ""
    else
	    echo "rmt-ca.crt found."
    fi

    echo ""

    if [ ! -e ${_container_base_path}/etc/rmt/ssl/rmt-server.crt ]; then
        echo "rmt-server.crt not found."
        certstrap --depot-path ${_container_base_path}/etc/rmt/ssl/ request-cert -domain ${_hostname} --passphrase "" --common-name rmt-server
	    certstrap --depot-path ${_container_base_path}/etc/rmt/ssl/ sign rmt-server --CA "rmt-ca"
    else
        echo "rmt-server.crt found."
    fi

    console___write ""
    console___write "---- Pull Container Image ----"
    console___write ""

    podman pull ${_container_image}


    console___write ""
    console___write "---- Start RMT ----"
    console___write ""

    # start as daemon
    _command="podman run -d -t "

    # start interactive
    #_command="podman run -i -t --rm "

    _command="${_command} --name ${_container_name}"
    
    _command="${_command} -v ${_container_base_path}/var/lib/mysql:/var/lib/mysql"
    _command="${_command} -v ${_container_base_path}/var/lib/rmt:/var/lib/rmt"
    _command="${_command} -v ${_container_base_path}/etc/rmt/ssl:/etc/rmt/ssl"

    #rm -rf /tmp/container-entrypoint.d
    #rm -rf /tmp/container-entrypoint.sh
    #cp -r /home/a001480/container-images/rmt-server/container-entrypoint.d /tmp
    #cp -r /home/a001480/container-images/rmt-server/container-entrypoint.d /tmp
    #cp -r /home/a001480/container-images/rmt-server/container-entrypoint.sh /tmp
    #chown root:root /tmp/container-entrypoint.sh
    #chmod 755 /tmp/container-entrypoint.sh
    #_command="${_command} -v /tmp/container-entrypoint.d:/container-entrypoint.d"
    #_command="${_command} -v /tmp/container-entrypoint.sh:/container-entrypoint.sh"
    
    _command="${_command} -p ${_port_http}:80/tcp"
    _command="${_command} -p ${_port_https}:443/tcp"

    _command="${_command} -e MYSQL_PASSWORD=rmt"
    _command="${_command} -e SCC_USERNAME=${_scc_username}"
    _command="${_command} -e SCC_PASSWORD=${_scc_password}"
        
    _command="${_command} ${_container_image} "

    console___write "${_command}"

    console___write ""

    ${_command}

    console___write ""
    console___write "---- Result ----"
    console___write ""

    console___write "To enter RMT Server execute: ..........: podman exec -i -t ${_container_name} bash"
    console___write ""
    console___write "Repo URL (HTTP) .......................: http://${_hostname}/repo"
    console___write "Repo URL (HTTPS) ......................: https://${_hostname}/repo"

    console___write ""


    # podman ps -a

    
}

function container___stop ()
{
    local _id=""
    local _container_name=$( config_file___get_value "${config_file_full}" "container_name" )

    echo ""

    #### Stop Container
    echo "---- Stop Container ----"
    echo ""
    
    _id=$( podman ps --filter "name=opensuse-tumbleweed-rmt-server" --filter "status=running" --format "{{.ID}}" | xargs echo )
    
    echo "Container name: ${_container_name}"
    echo "Container ID: ${_id}."
            
    if ( ! is_empty "${_id}") ; then
        echo "Container status: running."
        podman stop ${_id} 1>/dev/null 2>&1
        echo "Container stopped."
    else
        echo "Container status: not running."
    fi

    echo ""


    #### Remove Container
    echo "---- Remove Container ----"
    echo ""
    
    _id=$( podman ps -all --filter "name=opensuse-tumbleweed-rmt-server" --format "{{.ID}}" | xargs echo )

    echo "Container name: ${_container_name}"
    echo "Container ID: ${_id}."

    if ( ! is_empty "${_id}") ; then
        echo "Container status: exists."
        podman rm -f ${_id} 1>/dev/null 2>&1
        echo "Container removed."
    else
        echo "Container status: does not exist" 
    fi

    echo ""


    #### Result
    echo "---- Script finished ----"
    echo ""
    echo "Container ${_container_name} stopped and removed."
    echo ""
    echo "Exit Code: 0"
    echo ""
    exit 0

}


function container___login()
{

    echo ""
    echo "---- Login to Container ----"
    echo ""

    local _id=""

    local _container_name=$( config_file___get_value "${config_file_full}" "container_name" )

    _id=$( podman ps --filter "name=opensuse-tumbleweed-rmt-server" --filter "status=running" --format "{{.ID}}" | xargs echo )

    echo "Container name: ${_container_name}"
    echo "Container ID: ${_id}."
        
    if ( ! is_empty "${_id}") ; then
        
        echo "Container status: running."
        echo "Login..."
        echo ""

        podman exec -i -t ${_container_name} bash
        
    else
        echo "Container status: not running."
    fi

    echo ""

}













###################################################################################################
# Main program
###################################################################################################

#### setup environment
script_file_full="$( realpath ${BASH_SOURCE[0]} )"
script_file="${script_file_full##*/}"
script_dir="${script_file_full%/*}"

config_file="${script_file%.*}.config"
config_file_full="${script_dir}/${config_file}"

#echo ""
#echo "---- Environment ----"
#echo ""
#echo "script_file_full ......................: ${script_file_full}"
#echo "script_file ...........................: ${script_file}"
#echo "script_dir ............................: ${script_dir}"
#echo "config_file ...........................: ${config_file}"
#echo "config_file_full ......................: ${config_file_full}"


#### check user
if ( ! is_root_user ) ; then
    usage
    exit 1
fi


#### check script command line args and execute
script_args_count=${#BASH_ARGV[@]}

if [[ ${script_args_count} -ne 1 ]] ; then 
    echo ""
    echo "Invalid arguments."
    echo ""
    echo "Try '$0 --help' for more information."
    echo ""
    exit 3
fi

for script_arg in ${BASH_ARGV[*]} ; do

    script_arg=${script_arg^^}
    
    case "$script_arg" in

        --START)                container___init
                                container___start
                                ;;
        --STOP)                 container___init
                                container___stop
                                ;;
        --LOGIN)                container___init
                                container___login
                                ;;
        --VERSION)              version ;;
        --HELP)                 usage ;; 
        *)                      echo ""
                                echo "Invalid arguments."
                                echo ""
                                echo "Try '$0 --help' for more information."
                                echo ""
                                exit 3

    esac

done

