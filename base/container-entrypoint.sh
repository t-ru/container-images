#!/bin/sh

set -e

# Handle a kill signal before the final "exec" command runs
#trap "{ exit 0; }" TERM INT

echo "number of args: $#"

# Process files in /container-entrypoint.d
#for _file in /container-entrypoint.d/*; do
#    
#    _file_extension="${_file##*.}"
#    
#    if [ "${_file_extension}" = "env" ] && [ -f "${_file}" ]; then
#
#        # source env files
#        echo "Sourcing: ${_file} $@"
#        set -a && . "${_file}" "$@" && set +a
#    
#    elif [ "${_file_extension}" = "sh" ] && [ -x "${_file}" ]; then
#
#        # run script files
#        echo "Executing: ${_file} $@"
#        "${_file}" "$@"
#
#    fi

#done




echo "Executing: $@"
exec "$@"

