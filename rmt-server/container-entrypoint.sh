#!/bin/sh

set -e

output_set_cyan()
{
    tput setaf 6
}

output_reset()
{
    tput sgr0
}

output_set_bold()
{
    tput bold
}


# Handle a kill signal before the final "exec" command runs
trap "{ exit 0; }" TERM INT


if [ -d "/container-entrypoint.d" ]; then
    chown root:root /container-entrypoint.d
    chmod 755 /container-entrypoint.d
    for _container_entrypoint in /container-entrypoint.d/*; do
        _extension="${_container_entrypoint##*.}"
        if [ -f "${_container_entrypoint}" ] && [ "${_extension}" = "env" ]; then
            chown root:root ${_container_entrypoint}
            chmod 644 ${_container_entrypoint}
        elif [ -f "${_container_entrypoint}" ] && [ "${_extension}" = "sh" ]; then
            chown root:root ${_container_entrypoint}
            chmod 755 ${_container_entrypoint}
        fi
    done
fi



# Process files in /container-entrypoint.d
if [ -d "/container-entrypoint.d" ]; then
    for _container_entrypoint in /container-entrypoint.d/*; do
        _extension="${_container_entrypoint##*.}"
        if [ -f "${_container_entrypoint}" ] && [ "${_extension}" = "env" ]; then
            
            # source env files
            #echo "Sourcing: ${_container_entrypoint} $@"
            #set -a && . "${_container_entrypoint}" "$@" && set +a

            echo ""
            output_set_cyan
            echo "---- Sourcing ${_container_entrypoint} ----"
            output_reset
            set -a && . "${_container_entrypoint}" && set +a
            echo ""
            
        elif [ -f "${_container_entrypoint}" ] && [ "${_extension}" = "sh" ] && [ -x "${_container_entrypoint}" ]; then
            
            # run script files
            #echo "Executing: ${_container_entrypoint} $@"
            #"${_container_entrypoint}" "$@"
            
            echo ""
            output_set_cyan
            echo "---- Executing ${_container_entrypoint} ----"
            output_reset
            "${_container_entrypoint}"
            echo ""

        fi
    done
fi

#for _file in /container-entrypoint.d/*; do
#    _file_extension="${_file##*.}"
#    if [ "${_file_extension}" = "env" ] && [ -f "${_file}" ]; then
#        # source env files
#        echo "Sourcing: ${_file} $@"
#        set -a && . "${_file}" "$@" && set +a
#    elif [ "${_file_extension}" = "sh" ] && [ -x "${_file}" ]; then
#        # run script files
#        echo "Executing: ${_file} $@"
#        "${_file}" "$@"
#    fi
#done

echo "number of args: $#"
echo "args: "$@""

# no command passed ... run a shell
if [ $# = 0 ]; then
    if [ -x /bin/bash ]; then
        set -- /bin/bash
    else
        set -- /bin/sh
    fi
fi

echo "Executing: $@"
exec "$@"
