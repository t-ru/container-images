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

#echo -e "database:\n  host: ${MYSQL_HOST}\n  database: ${MYSQL_DATABASE}\n  username: ${MYSQL_USER}\n  password: ${MYSQL_PASSWORD}" > /etc/rmt.conf
#echo -e "  adapter: mysql2\n  encoding: utf8\n  timeout: 5000\n  pool: 5\n" >> /etc/rmt.conf
#echo -e "scc:\n  username: ${SCC_USERNAME}\n  password:  ${SCC_PASSWORD}\n  sync_systems: true\n" >> /etc/rmt.conf
#echo -e "log_level:\n  rails: debug" >> /etc/rmt.conf

    # Default /etc/rmt.conf
    # !!! YAML config !!!
    #database:
    #  host: localhost
    #  database: rmt
    #  username: rmt
    #  password:
    #  adapter: mysql2
    #  encoding: utf8
    #  timeout: 5000
    #  pool: 5
    #
    #scc:
    #  username:
    #  password:
    #  sync_systems: true
    #
    #mirroring:
    #  mirror_src: false
    #  verify_rpm_checksums: false
    #  dedup_method: hardlink
    #
    #http_client:
    #  verbose: false
    #  proxy:
    #  proxy_auth:
    #  proxy_user:
    #  proxy_password:
    #  low_speed_limit: 512
    #  low_speed_time: 120
    #
    #log_level:
    #  rails: info
    #
    #web_server:
    #  min_threads: 5
    #  max_threads: 5
    #  workers: 2


rmt_config_file="/etc/rmt.conf"
> ${rmt_config_file}

echo -e "database:\n" \
        "  host: ${MYSQL_HOST}\n" \
        "  database: ${MYSQL_DATABASE}\n" \
        "  username: ${MYSQL_USER}\n"  \
        "  password: ${MYSQL_PASSWORD}\n" \
        "  adapter: mysql2\n" \
        "  encoding: utf8\n" \
        "  timeout: 5000\n" \
        "  pool: 5\n" \
        >> ${rmt_config_file}

echo -e "scc:\n" \
        "  username: ${SCC_USERNAME}\n" \
        "  password: ${SCC_PASSWORD}\n" \
        "  sync_systems: true\n" \
        >> ${rmt_config_file}

echo -e "mirroring:\n" \
        "  mirror_src: false\n" \
        "  verify_rpm_checksums: false\n" \
        "  dedup_method: hardlink\n" \
        >> ${rmt_config_file}

echo -e "http_client:\n" \
        "  verbose: false\n" \
        "  proxy:\n" \
        "  proxy_auth:\n" \
        "  proxy_user:\n" \
        "  proxy_password:\n" \
        "  low_speed_limit: 512\n" \
        "  low_speed_time: 120\n" \
        >> ${rmt_config_file}

echo -e "log_level:\n" \
        "  rails: info\n" >> ${rmt_config_file}

echo -e "web_server:\n" \
        "  min_threads: 5\n" \
        "  max_threads: 5\n" \
        "  workers: 2\n" \
        >> ${rmt_config_file}

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