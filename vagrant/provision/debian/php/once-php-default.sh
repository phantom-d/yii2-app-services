#!/usr/bin/env bash

#== Import script args ==

app_path=$(echo "$1")
www_path=$(dirname ${app_path})
guest_ip=$(echo "$2")
host_ip=$(echo ${guest_ip} | sed 's/[[:digit:]][[:digit:]][[:digit:]]$/1/g')
gateway=$(netstat -nr | awk '$1 == "0.0.0.0"{print$2}')

#== Bash helpers ==

function info {
  echo " "
  echo "--> $1"
  echo " "
}

#== Provision script ==

info "Provision-script user: `whoami`"

export DEBIAN_FRONTEND=noninteractive

info "Install XHprof profiler"
[ ! -d ${www_path} ] && mkdir -p ${www_path}
cd ${www_path}

[ -d './xhprof' ] && rm -Rf xhprof

wget --quiet http://pecl.php.net/get/xhprof-0.9.4.tgz -O xhprof.tgz
gzip -d xhprof.tgz && tar -xvf xhprof.tar
mv -f xhprof-0.9.4 xhprof && rm -f xhprof.tar package.xml
mkdir ./xhprof/logs
chown -R vagrant:vagrant ./xhprof
info "Done!"

info "Update OS software"
echo "deb http://packages.dotdeb.org $(lsb_release -sc) all" | tee /etc/apt/sources.list.d/dotdeb.list
echo "deb-src http://packages.dotdeb.org $(lsb_release -sc) all" | tee -a /etc/apt/sources.list.d/dotdeb.list
wget --quiet -O - https://www.dotdeb.org/dotdeb.gpg | apt-key add -

apt-get update -qq
apt-get upgrade -y
apt-get autoremove -y
info "Done!"

info "Install PHP5"
apt-get install -y php5-dev php5-cli php5-fpm php5-intl php5-mysqlnd php5-curl php5-xdebug php5-xhprof\
                php5-gd php5-imagick php-mbstring php-zip graphviz

apt-get autoremove -y
info "Done!"

info "Configure PHP5-FPM"
sed -i 's/user = www-data/user = vagrant/g' /etc/php5/fpm/pool.d/www.conf
sed -i 's/group = www-data/group = vagrant/g' /etc/php5/fpm/pool.d/www.conf
sed -i 's/owner = www-data/owner = vagrant/g' /etc/php5/fpm/pool.d/www.conf
sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php5/fpm/pool.d/www.conf

sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php5/fpm/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php5/cli/php.ini

sed -i 's/;date.timezone =/date.timezone = "'${timezone//\//\\/}'"/g' /etc/php5/fpm/php.ini
sed -i 's/;date.timezone =/date.timezone = "'${timezone//\//\\/}'"/g' /etc/php5/cli/php.ini

sed -i 's/memory_limit = 128M/memory_limit = -1/g' /etc/php5/fpm/php.ini
sed -i 's/memory_limit = 128M/memory_limit = -1/g' /etc/php5/cli/php.ini

[ -L /etc/php5/cli/conf.d/20-xhprof.ini ] && rm -f /etc/php5/cli/conf.d/20-xhprof.ini
ln -s ../../mods-available/xhprof.ini /etc/php5/cli/conf.d/20-xhprof.ini
[ -L /etc/php5/fpm/conf.d/20-xhprof.ini ] && rm -f /etc/php5/fpm/conf.d/20-xhprof.ini
ln -s ../../mods-available/xhprof.ini /etc/php5/fpm/conf.d/20-xhprof.ini

echo "extension = xhprof.so" | tee /etc/php5/mods-available/xhprof.ini
echo 'xhprof.output_dir = "'${www_path}'/xhprof/logs"' >> /etc/php5/mods-available/xhprof.ini

info "Done!"

info "Configure PHP XDebug"
cat > /etc/php5/mods-available/xdebug_cli.ini<<-FILE
[xdebug]
zend_extension=xdebug.so
xdebug.max_nesting_level=1000

xdebug.default_enable=1
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_autostart=1
xdebug.remote_host=${gateway}
xdebug.remote_port=9000
xdebug.remote_handler="dbgp"
debug.remote_log=/var/log/php5-xdebug-cli.log
xdebug.idekey=PHPSTORM

FILE

cat > /etc/php5/mods-available/xdebug.ini<<-FILE
[xdebug]
zend_extension=xdebug.so
xdebug.max_nesting_level=1000

xdebug.default_enable=1
xdebug.remote_enable=1
xdebug.remote_host=${host_ip}
xdebug.remote_port=9000
xdebug.remote_handler="dbgp"
debug.remote_log=/var/log/php5-xdebug.log
xdebug.idekey=PHPSTORM

FILE

info "Done!"

echo "Script php/once-php-default.sh Done"