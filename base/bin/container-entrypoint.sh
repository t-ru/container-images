#!/bin/sh

set -e

# Handle a kill signal before the final "exec" command runs
trap "{ exit 0; }" TERM INT









echo "Executing: $@"
exec "$@"

