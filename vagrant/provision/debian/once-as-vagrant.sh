#!/usr/bin/env bash

#== Import script args ==

github_token=$(echo "$1")
app_path=$(echo "$2")

#== Bash helpers ==

function info {
  echo " "
  echo "--> $1"
  echo " "
}

#== Provision script ==

info "Provision-script user: `whoami`"

info "Configure composer"
sed -i "s/^COMPOSER_HOME.*//" /home/vagrant/.profile
sed -i "s/^XDEBUG_CONFIG.*//" /home/vagrant/.profile
sed -i "s/^PATH.*//" /home/vagrant/.profile
sed -i '/^\s*$/d' /home/vagrant/.profile
sed -i '/^\s*$/d' /home/vagrant/.bashrc

echo 'COMPOSER_HOME="/home/vagrant/.composer"' | tee -a /home/vagrant/.profile
echo 'PATH='${app_path}'/vendor/bin:${COMPOSER_HOME}/vendor/bin:$PATH' | tee -a /home/vagrant/.profile
echo 'XDEBUG_CONFIG="idekey=PHPSTORM"' | tee -a /home/vagrant/.profile

. /home/vagrant/.bashrc

rm -Rf ${COMPOSER_HOME}
composer global config github-oauth.github.com ${github_token}
composer global config repositories.assets '{"type": "composer", "url": "https://asset-packagist.org"}'
composer global require "codeception/codeception=2.0.*" "codeception/specify=*" "codeception/verify=*" --no-update
info "Done!"

info "Install plugins for composer and codeception"
composer global install --no-progress --prefer-dist
info "Done!"

info "Install project dependencies"
cd ${app_path}
composer --no-progress --prefer-dist install
info "Done!"

info "Init project"
./init --env=Development --overwrite=y
info "Done!"

info "Apply migrations"
./yii migrate --interactive=0
info "Done!"

info "Create bash-alias 'app' for vagrant user"
echo 'alias app="cd '${app_path}'"' | tee /home/vagrant/.bash_aliases
echo 'alias tests="cd '${app_path}'/tests"' | tee -a /home/vagrant/.bash_aliases
echo 'alias logs="cd '${app_path}'/vagrant/logs"' | tee -a /home/vagrant/.bash_aliases
info "Done!"

info "Enabling colorized prompt for guest console"
sed -i "s/#force_color_prompt=yes/force_color_prompt=yes/" /home/vagrant/.bashrc

echo "Script `basename $0` Done"
