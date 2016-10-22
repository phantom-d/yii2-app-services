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

if [ ! -f /swapfile ]; then
    info "Allocate swap for DB server"
    fallocate -l 2048M /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap defaults 0 0' | tee -a /etc/fstab
fi

info "Install Postgresql-9.6 server"
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" | tee /etc/apt/sources.list.d/postgres.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

apt-get update -qq
apt-get upgrade -y
apt-get autoremove -y
apt-get -q -y install postgresql-9.6

systemctl enable postgresql-9.6
info "Done!"

info "Configure Postgresql-9.6 server"
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'\t/" /etc/postgresql/9.6/main/postgresql.conf
sed -i "s/host    all             all             127.0.0.1\/32            md5/host    all             all             0.0.0.0\/0               trust/" /etc/postgresql/9.6/main/pg_hba.conf
info "Done!"

info "Initailize databases for Postgresql-9.6 server"
sudo -u postgres psql <<< "CREATE DATABASE "${db_name}" ENCODING 'utf8' TEMPLATE template0;"
sudo -u postgres psql <<< "CREATE DATABASE "${db_name}"_tests ENCODING 'utf8' TEMPLATE template0;"
info "Done!"

echo "Script db/once-percona-5.7.sh Done"
