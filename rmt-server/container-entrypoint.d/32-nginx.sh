#!/bin/bash

script_file_full="$( realpath ${BASH_SOURCE[0]} )"

tput setaf 6
echo ""
echo "---- Nginx (${script_file_full}) ----"
tput sgr0

systemctl start nginx.service

echo ""
echo "Done."