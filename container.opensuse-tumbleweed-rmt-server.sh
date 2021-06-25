#!/bin/bash

###################################################################################################
# Global Variables
###################################################################################################


###################################################################################################
# Functions
###################################################################################################

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
# FUNCTION: return_header_string()
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

function script_header___get_copyright() 
{
    local _file="${1}"
    local _result=$( script_header___get_string "Copyright" "${script_file_full}" )
    echo -n "${_result}"
}


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
# FUNCTION: usage()
#   -   show version of script
function version ()
{
    echo ""
    echo "${script_file}"
    echo ""
    echo "Version $( script_header___get_version '${script_file_full}' )"
    echo ""
}

function start ()
{
    echo ""
    echo "start"
    echo ""

    local _container_image=""
    local _container_name=""

    local _rmt_base_path=""
    local _rmt_mariadb_path=""
    
    _container_image=$( config_file___get_value "${config_file_full}" "container_image" )
    _container_name=$( config_file___get_value "${config_file_full}" "container_name" )
    _rmt_base_path=$( config_file___get_value "${config_file_full}" "rmt_base_path" )


    _rmt_mariadb_path="${_rmt_base_path}/mariadb"


    
    
    echo ${_container_image}
    echo ${_container_name}
    echo ${_rmt_server_path}

    # Create directories
    [ ! -d ${_rmt_base_path} ] && mkdir -p ${_rmt_base_path}
    [ ! -d ${_rmt_base_path}/var/lib/mysql ] && mkdir -p ${_rmt_base_path}/var/lib/mysql
    [ ! -d ${_rmt_base_path}/var/lib/rmt ] && mkdir -p ${_rmt_base_path}/var/lib/rmt



    



    






    

    _command="podman run -d --rm"
    _command="podman run -i -t --rm "
    
    _command="${_command} --name ${_container_name}"



    

    rm -rf /tmp/container-entrypoint.d
    rm -rf /tmp/container-entrypoint.sh
    
    cp -r /home/a001480/container-images/rmt-server/container-entrypoint.d /tmp
    cp -r /home/a001480/container-images/rmt-server/container-entrypoint.d /tmp
    cp -r /home/a001480/container-images/rmt-server/container-entrypoint.sh /tmp

    
    _dir="/tmp/container-entrypoint.d"

    _command="${_command} -v ${_dir}:/container-entrypoint.d"

    #mntdir=$(mktemp -d /run/XXXXX)
    #mounts=$(findmnt -n -m -R /sys/fs/cgroup/ | awk '{ print $1 }'| tail -n +2)
    #for m in ${mounts}; do
    #mkdir -p ${mntdir}/$m
    #mount --bind -o ro $m ${mntdir}/$m
    #done
    #mount -o rw,remount ${mntdir}/sys/fs/cgroup/systemd
    #echo "-v ${mntdir}:/sys/fs/cgroup"

    #_command="${_command} -v ${mntdir}:/sys/fs/cgroup"
    
    

    _command="${_command} -v ${_rmt_base_path}/var/lib/mysql:/var/lib/mysql"
    _command="${_command} -v ${_rmt_base_path}/var/lib/rmt:/var/lib/rmt"
    _command="${_command} -e MYSQL_PASSWORD=rmt"
    

    
    





    _command="${_command} ${_container_image} "





     echo "${_command}"

     ${_command}


    echo "podman exec -i -t ${_container_name} bash"


    # https://developers.redhat.com/blog/2019/04/24/how-to-run-systemd-in-a-container#other_cool_features_about_podman_and_systemd
    # https://blog.while-true-do.io/podman-systemd-in-containers/
    # https://github.com/moby/moby/issues/18922




}

function stop ()
{
   
    podman stop opensuse-tumbleweed-rmt-server

}


#--------------------------------------------------------------------------------------------------
# FUNCTION: usage()
#   -   show usage of script
function usage()
{

    echo ""
    echo "---- Usage ----"
    echo ""
    echo "    as root user:     ${0} [options]"
    echo "    with sudo:        sudo ${0} [options]"
    
    echo ""
    echo "---- Options ----"
    echo ""
    echo "    --start           start container"
    echo "    --stop            stop container"
    echo "    --version         display version information and exit"
    echo "    --help            display this help and exit"
    
    echo ""
    echo "---- Info ----"
    echo ""
    echo "    Script:           ${script_file}"
    echo "    Description:      $( script_header___get_description '${script_file_full}' )"
    echo "    Author:           $( script_header___get_author '${script_file_full}' )"
    echo "    Copyright:        $( script_header___get_copyright '${script_file_full}' )"
    echo "    Version:          $( script_header___get_version '${script_file_full}' )"

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

echo ""
echo "---- Environment ----"
echo ""
echo "script_file_full ......................: ${script_file_full}"
echo "script_file ...........................: ${script_file}"
echo "script_dir ............................: ${script_dir}"
echo "config_file ...........................: ${config_file}"
echo "config_file_full ......................: ${config_file_full}"

#### check script command line args and execute
script_args_count=${#BASH_ARGV[@]}

if [[ ${script_args_count} -ne 1 ]] ; then 
    echo ""
    echo "Missing arguments."
    echo ""
    echo "Try '$0 --help' for more information."
    echo ""
    exit 2
fi

for script_arg in ${BASH_ARGV[*]} ; do

    script_arg=${script_arg^^}
    
    case "$script_arg" in

        --START)        start;;
        --STOP)         stop;;
        
        --VERSION)      version ;;
        --HELP)         usage ;; 
        *)              echo ""
                        echo "Invalid arguments."
                        echo ""
                        echo "Try '$0 --help' for more information."
                        echo ""
                        exit 3

    esac

done

