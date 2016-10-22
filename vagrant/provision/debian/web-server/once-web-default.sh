#!/usr/bin/env bash

#== Import script args ==

app_path=$(echo "$1")

#== Bash helpers ==

function info {
  echo " "
  echo "--> $1"
  echo " "
}

#== Provision script ==

info "Provision-script user: `whoami`"

export DEBIAN_FRONTEND=noninteractive

info "Update OS software"
echo "deb http://packages.dotdeb.org $(lsb_release -sc) all" | tee /etc/apt/sources.list.d/dotdeb.list
echo "deb-src http://packages.dotdeb.org $(lsb_release -sc) all" | tee -a /etc/apt/sources.list.d/dotdeb.list
wget --quiet -O - https://www.dotdeb.org/dotdeb.gpg | apt-key add -

apt-get update -qq
apt-get upgrade -y
info "Done!"

info "Enabling site configuration"
mkdir -p /etc/nginx/conf.d
[ -f /etc/nginx/conf.d/app.conf ] && rm -f /etc/nginx/conf.d/app.conf
[ -L /etc/nginx/conf.d/app.conf ] && rm -f /etc/nginx/conf.d/app.conf
ln -s `echo ${app_path}`/vagrant/config/nginx-app.conf /etc/nginx/conf.d/app.conf
info "Done!"

info "Install additional software"
apt-get install -y nginx

systemctl unmask nginx.service
systemctl enable nginx.service
apt-get autoremove -y
info "Done!"

info "Configure NGINX"
sed -i 's/user  nginx/user vagrant/g' /etc/nginx/nginx.conf
sed -i 's/user www-data/user vagrant/g' /etc/nginx/nginx.conf
info "Done!"

echo "Script web-server/once-web-default.sh Done"