#!/bin/bash

script_file_full="$( realpath ${BASH_SOURCE[0]} )"

tput setaf 6
echo ""
echo "---- RMT Server (${script_file_full}) ----"
tput sgr0

systemctl start rmt-server.service

echo ""
echo "Done."
