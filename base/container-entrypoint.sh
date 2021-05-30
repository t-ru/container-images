#!/bin/sh

set -e

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
            chmod 744 ${_container_entrypoint}
        fi
    done
fi




# Process files in /container-entrypoint.d
for _file in /container-entrypoint.d/*; do
    _file_extension="${_file##*.}"
    if [ "${_file_extension}" = "env" ] && [ -f "${_file}" ]; then
        # source env files
        echo "Sourcing: ${_file} $@"
        set -a && . "${_file}" "$@" && set +a
    elif [ "${_file_extension}" = "sh" ] && [ -x "${_file}" ]; then
        # run script files
        echo "Executing: ${_file} $@"
        "${_file}" "$@"
    fi
done

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
