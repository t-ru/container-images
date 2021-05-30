#!/bin/sh

set -e

# Handle a kill signal before the final "exec" command runs
trap "{ exit 0; }" TERM INT


chown root:root /container-entrypoint.d/*.env 2>/dev/null
chown root:root /container-entrypoint.d/*.sh 2>/dev/null
chmod 644 /container-entrypoint.d/*.env 2>/dev/null
chmod 744 /container-entrypoint.d/*.sh 2>/dev/null



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
