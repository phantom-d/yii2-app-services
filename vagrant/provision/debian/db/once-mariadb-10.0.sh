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

info "Update OS software"
echo "deb http://packages.dotdeb.org $(lsb_release -sc) all" | tee /etc/apt/sources.list.d/dotdeb.list
echo "deb-src http://packages.dotdeb.org $(lsb_release -sc) all" | tee -a /etc/apt/sources.list.d/dotdeb.list
wget --quiet -O - https://www.dotdeb.org/dotdeb.gpg | apt-key add -

apt-get update -qq
apt-get upgrade -y
apt-get autoremove -y
info "Done!"

info "Prepare root password for MariaDB server"
debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password password \"''\""
debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password_again password \"''\""
info "Done!"

apt-get install -y mariadb-server-10.0

info "Configure MariaDB server"
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
info "Done!"

info "Initailize databases for MariaDB server"
mysql -uroot <<< "CREATE DATABASE IF NOT EXISTS "${db_name}" CHARACTER SET utf8 COLLATE utf8_unicode_ci"
mysql -uroot <<< "CREATE DATABASE IF NOT EXISTS "${db_name}"_tests CHARACTER SET utf8 COLLATE utf8_unicode_ci"
info "Done!"

echo "Script db/once-mariadb-10.0.sh Done"
