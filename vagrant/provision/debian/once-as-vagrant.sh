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
sed -i "s/^PATH.*//" /home/vagrant/.profile
sed -i "s/^export COMPOSER_HOME.*//" /home/vagrant/.bashrc
sed -i '/^\s*$/d' /home/vagrant/.profile
sed -i '/^\s*$/d' /home/vagrant/.bashrc

echo 'COMPOSER_HOME="/home/vagrant/.config/composer"' | tee -a /home/vagrant/.profile
echo 'PATH='${app_path}'/vendor/bin:${COMPOSER_HOME}/vendor/bin:$PATH' | tee -a /home/vagrant/.profile
echo 'export COMPOSER_HOME="/home/vagrant/.config/composer"' | tee -a /home/vagrant/.bashrc
echo 'export XDEBUG_CONFIG="idekey=PHPSTORM"' | tee -a /home/vagrant/.bashrc

. /home/vagrant/.bashrc

rm -Rf ${COMPOSER_HOME}
composer global config repositories.assets '{"type": "composer", "url": "https://asset-packagist.org"}'
composer global config github-oauth.github.com ${github_token}
echo "Done!"

info "Install plugins for composer and codeception"
composer global install --no-progress --prefer-dist

info "Install project dependencies"
cd ${app_path}
composer --no-progress --prefer-dist install
echo "Done!"

info "Init project"
./init --env=Development --overwrite=y
echo "Done!"

info "Apply migrations"
./yii migrate --interactive=0
echo "Done!"

info "Create bash-alias 'app' for vagrant user"
echo 'alias app="cd '${app_path}'"' | tee /home/vagrant/.bash_aliases
echo 'alias tests="cd '${app_path}'/tests"' | tee -a /home/vagrant/.bash_aliases
echo "Done!"

info "Enabling colorized prompt for guest console"
sed -i "s/#force_color_prompt=yes/force_color_prompt=yes/" /home/vagrant/.bashrc

echo "Script once-as-vagrant.sh Done"