#!/bin/bash

script_file_full="$( realpath ${BASH_SOURCE[0]} )"

tput setaf 6
echo ""
echo "---- Maria DB: Startup (${script_file_full}) ----"
tput sgr0

systemctl start mariadb.service

echo ""
echo "Done."

