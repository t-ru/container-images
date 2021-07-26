#!/bin/sh
set -e

script_file_full="$( realpath ${BASH_SOURCE[0]} )"

tput setaf 6
echo ""
echo "---- RMT Server: Prepare startup (${script_file_full}) ----"
echo ""
tput sgr0

# Create directories on /var/lib/rmt (if required)
echo "**** Create directories on /var/lib/rmt (if required) ****"
echo ""
mkdir -p /var/lib/rmt/public/repo
mkdir -p /var/lib/rmt/public/suma
mkdir -p /var/lib/rmt/regsharing
mkdir -p /var/lib/rmt/tmp
echo "Done."

# Fix owner:group on /var/lib/rmt (if required)
echo ""
echo "**** Fix owner:group on /var/lib/rmt (if required) ****"
echo ""
echo "This may take a while..."
echo ""
find /var/lib/rmt -not \( -user _rmt -a -group nginx \) -exec chown _rmt:nginx {} \;
echo "Done."

# Check Env Variables
echo ""
echo "**** Check Env Variables ****"
echo ""
if [ -z "${MYSQL_HOST}" ]; then
	echo "Error: MYSQL_HOST not set!"
	exit 1
fi
if [ -z "${MYSQL_PASSWORD}" ]; then
        echo "Error: MYSQL_PASSWORD not set!"
        exit 1
fi

MYSQL_DATABASE="${MYSQL_DATABASE:-rmt}"
MYSQL_USER="${MYSQL_USER:-rmt}"

echo "Done."


# Create adjusted /etc/rmt.conf
echo ""
echo "**** Create adjusted /etc/rmt.conf ****"
echo ""
echo -e "database:\n  host: ${MYSQL_HOST}\n  database: ${MYSQL_DATABASE}\n  username: ${MYSQL_USER}\n  password: ${MYSQL_PASSWORD}" > /etc/rmt.conf
echo -e "  adapter: mysql2\n  encoding: utf8\n  timeout: 5000\n  pool: 5\n" >> /etc/rmt.conf
echo -e "scc:\n  username: ${SCC_USERNAME}\n  password:  ${SCC_PASSWORD}\n  sync_systems: true\n" >> /etc/rmt.conf
echo -e "log_level:\n  rails: debug" >> /etc/rmt.conf
echo "Done."


# Create / migrate RMT database
echo ""
echo "**** Create / migrate RMT database ****"
echo ""

pushd /usr/share/rmt > /dev/null
/usr/share/rmt/bin/rails db:create db:migrate RAILS_ENV=production
popd > /dev/null
echo ""
echo "Done."