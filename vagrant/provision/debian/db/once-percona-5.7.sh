#!/usr/bin/env bash

#== Import script args ==

app_path=$(echo "$1")
db_name=$(echo "$2")

#== Bash helpers ==

function info {
  echo " "
  echo "--> $1"
  echo " "
}

#== Provision script ==

info "Provision-script user: `whoami`"

export DEBIAN_FRONTEND=noninteractive

if [ ! -f /swapfile ]; then
    info "Allocate swap for DB server"
    fallocate -l 2048M /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap defaults 0 0' | tee -a /etc/fstab
fi

info "Configure Percona-5.7 server"
mkdir -p /etc/mysql/conf.d/
echo "[mysqld]" | tee /etc/mysql/conf.d/sql_mode.cnf
echo "sql_mode=''" | tee -a /etc/mysql/conf.d/sql_mode.cnf
chmod 644 /etc/mysql/conf.d/sql_mode.cnf
info "Done!"

info "Prepare root password for Percona-5.7 server"
debconf-set-selections <<< "percona-server-server-5.7 percona-server-server/root_password password \"''\""
debconf-set-selections <<< "percona-server-server-5.7 percona-server-server/root_password_again password \"''\""
info "Done!"

info "Install Percona server"
wget --quiet https://repo.percona.com/apt/percona-release_0.1-3.$(lsb_release -sc)_all.deb -O /tmp/percona-release.deb
gdebi -n /tmp/percona-release.deb
apt-get update -qq
apt-get upgrade -y
apt-get autoremove -y
apt-get -q -y install percona-server-server-5.7
info "Done!"

info "Configure Percona-5.7 server"
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
mysql -e "DROP FUNCTION IF EXISTS fnv1a_64; CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
mysql -e "DROP FUNCTION IF EXISTS fnv_64; CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
mysql -e "DROP FUNCTION IF EXISTS murmur_hash; CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"
info "Done!"

info "Initailize databases for Percona-5.7 server"
mysql -uroot <<< "CREATE DATABASE IF NOT EXISTS "${db_name}" CHARACTER SET utf8 COLLATE utf8_unicode_ci"
mysql -uroot <<< "CREATE DATABASE IF NOT EXISTS "${db_name}"_tests CHARACTER SET utf8 COLLATE utf8_unicode_ci"
info "Done!"

echo "Script db/once-percona-5.7.sh Done"
