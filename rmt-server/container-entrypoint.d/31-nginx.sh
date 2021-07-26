#!/bin/sh

#!/bin/bash

script_file_full="$( realpath ${BASH_SOURCE[0]} )"

tput setaf 6
echo ""
echo "---- Nginx: Prepare startup (${script_file_full}) ----"
tput sgr0

echo ""
echo "Done."
