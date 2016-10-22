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

info "Install PHP7.0"
apt-get install -y php7.0-dev php7.0-cli php7.0-fpm php7.0-intl php7.0-mysqlnd php7.0-curl php7.0-xdebug\
                php7.0-gd php7.0-imagick php7.0-mbstring php7.0-zip graphviz

apt-get autoremove -y
info "Done!"

info "Install XHprof PHP7 module"
cd /usr/src
git clone -b php7 https://github.com/RustJason/xhprof.git
cd xhprof/extension
phpize
./configure --with-php-config=/usr/bin/php-config
make && make install

cd ../.. && rm -Rf xhprof

[ -L /etc/php/7.0/cli/conf.d/20-xhprof.ini ] && rm -f /etc/php/7.0/cli/conf.d/20-xhprof.ini
ln -s ../../mods-available/xhprof.ini /etc/php/7.0/cli/conf.d/20-xhprof.ini
[ -L /etc/php/7.0/fpm/conf.d/20-xhprof.ini ] && rm -f /etc/php/7.0/fpm/conf.d/20-xhprof.ini
ln -s ../../mods-available/xhprof.ini /etc/php/7.0/fpm/conf.d/20-xhprof.ini

echo "extension = xhprof.so" | tee /etc/php/7.0/mods-available/xhprof.ini
echo 'xhprof.output_dir = "'${app_path}'/vagrant/log/xhprof"' >> /etc/php/7.0/mods-available/xhprof.ini
info "Done!"

info "Configure PHP-FPM 7.0"
sed -i 's/user = www-data/user = vagrant/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/group = www-data/group = vagrant/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/owner = www-data/owner = vagrant/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php/7.0/fpm/php.ini
sed -i 's/memory_limit = .+/memory_limit = -1/g' /etc/php/7.0/fpm/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php/7.0/cli/php.ini
sed -i 's/memory_limit = .+/memory_limit = -1/g' /etc/php/7.0/cli/php.ini

[ -L /etc/php/7.0/cli/conf.d/20-xdebug.ini ] && rm -f /etc/php/7.0/cli/conf.d/20-xdebug.ini
ln -s ../../mods-available/xdebug_cli.ini /etc/php/7.0/cli/conf.d/20-xdebug.ini

cat > /etc/php/7.0/mods-available/xdebug_cli.ini<<-FILE
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
debug.remote_log=/var/log/php7.0-xdebug-cli.log
xdebug.idekey=PHPSTORM

FILE

cat > /etc/php/7.0/mods-available/xdebug.ini<<-FILE
[xdebug]
zend_extension=xdebug.so
xdebug.max_nesting_level=1000

xdebug.default_enable=1
xdebug.remote_enable=1
xdebug.remote_host=${host_ip}
xdebug.remote_port=9000
xdebug.remote_handler="dbgp"
debug.remote_log=/var/log/php7.0-xdebug.log
xdebug.idekey=PHPSTORM

FILE

info "Done!"

echo "Script php/once-php-default.sh Done"