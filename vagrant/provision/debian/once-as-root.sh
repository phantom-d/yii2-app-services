#!/usr/bin/env bash

#== Import script args ==

timezone=$(echo "$1")
app_path=$(echo "$2")
www_path=$(dirname ${app_path})
guest_ip=$(echo "$3")
db_name=$(echo "$4")
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

if [ ! -f /swapfile ]; then
    info "Allocate swap for Percona server 5.7"
    fallocate -l 2048M /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap defaults 0 0' | tee -a /etc/fstab
fi

info "Configure timezone"
echo ${timezone} | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata


info "Install XHprof profiler"
[ ! -d ${www_path} ] && mkdir -p ${www_path}
cd ${www_path}

[ -d './xhprof' ] && rm -Rf xhprof

wget --quiet http://pecl.php.net/get/xhprof-0.9.4.tgz -O xhprof.tgz
gzip -d xhprof.tgz && tar -xvf xhprof.tar
mv -f xhprof-0.9.4 xhprof && rm -f xhprof.tar package.xml
mkdir ./xhprof/logs
chown -R vagrant:vagrant ./xhprof
echo "Done!"

info "Update OS software"
echo "deb http://nginx.org/packages/debian/ $(lsb_release -sc) nginx" | tee /etc/apt/sources.list.d/nginx.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62

echo "deb http://packages.dotdeb.org $(lsb_release -sc) all" | tee /etc/apt/sources.list.d/dotdeb.list
echo "deb-src http://packages.dotdeb.org $(lsb_release -sc) all" | tee -a /etc/apt/sources.list.d/dotdeb.list
wget --quiet -O - https://www.dotdeb.org/dotdeb.gpg | apt-key add -

apt-get update -qq
apt-get upgrade -y
echo "Done!"

info "Enabling site configuration"
mkdir -p /etc/nginx/conf.d
[ -f /etc/nginx/conf.d/app.conf ] && rm -f /etc/nginx/conf.d/app.conf
[ -L /etc/nginx/conf.d/app.conf ] && rm -f /etc/nginx/conf.d/app.conf
ln -s `echo ${app_path}`/vagrant/config/nginx-app.conf /etc/nginx/conf.d/app.conf
echo "Done!"

info "Configure Percona server"
mkdir -p /etc/mysql/conf.d/
[ -f /etc/mysql/conf.d/sql_mode.cnf ] && rm -f /etc/mysql/conf.d/sql_mode.cnf
cp -f ${app_path}/vagrant/config/sql_mode.cnf /etc/mysql/conf.d/sql_mode.cnf
chmod 644 /etc/mysql/conf.d/sql_mode.cnf
echo "Done!"

info "Install additional software"
apt-get install -y git php5-dev php5-cli php5-fpm php5-intl php5-mysqlnd php5-curl php5-xdebug php5-xhprof\
                php5-gd php5-imagick nginx mc htop graphviz gdebi locales-all mytop

systemctl unmask nginx.service
systemctl enable nginx.service
apt-get autoremove -y
echo "Done!"

info "Configure locales"
localectl set-locale LANG=ru_RU.utf8

info "Prepare root password for Percona server"
debconf-set-selections <<< "percona-server-server-5.7 percona-server-server/root_password password \"''\""
debconf-set-selections <<< "percona-server-server-5.7 percona-server-server/root_password_again password \"''\""
echo "Done!"

info "Install Percona server"
wget --quiet https://repo.percona.com/apt/percona-release_0.1-3.$(lsb_release -sc)_all.deb -O /tmp/percona-release.deb
gdebi -n /tmp/percona-release.deb
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9334A25F8507EFA5
apt-get update -qq
apt-get -q -y install percona-server-server-5.7
echo "Done!"

info "Configure Percona server"
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
mysql -e "DROP FUNCTION IF EXISTS fnv1a_64; CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
mysql -e "DROP FUNCTION IF EXISTS fnv_64; CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
mysql -e "DROP FUNCTION IF EXISTS murmur_hash; CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"
mysql -e "DROP USER IF EXISTS 'vagrant'@'%'; CREATE USER 'vagrant'@'%' IDENTIFIED BY 'vagrant'; GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%'; FLUSH PRIVILEGES;"
echo "Done!"

info "Configure PHP-FPM"
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
echo "Done!"

info "Configure NGINX"
sed -i 's/user  nginx/user vagrant/g' /etc/nginx/nginx.conf
sed -i 's/user www-data/user vagrant/g' /etc/nginx/nginx.conf
echo "Done!"

info "Initailize databases for Percona server"
mysql -uroot <<< "CREATE DATABASE IF NOT EXISTS "${db_name}" CHARACTER SET utf8 COLLATE utf8_unicode_ci"
mysql -uroot <<< "CREATE DATABASE IF NOT EXISTS "${db_name}"_tests CHARACTER SET utf8 COLLATE utf8_unicode_ci"
echo "Done!"

info "Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
echo "Done!"

info "Create bash-alias for root user"
echo 'alias app="cd '${app_path}'"' | tee /root/.bash_aliases
echo 'alias logs="cd '${app_path}'/vgrant/logs"' | tee -a /root/.bash_aliases
echo "Done!"

if [ -z "`grep -i 'force_color_prompt' /root/.bashrc`" ]; then
    info "Enabling colorized prompt for guest console"
    cat >> /root/.bashrc<<-FILE

force_color_prompt=yes

if [ -n "\$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "\$color_prompt" = yes ]; then
    PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\$ '
else
    PS1='\${debian_chroot:+(\$debian_chroot)}\u@\h:\w\\$ '
fi

unset color_prompt force_color_prompt

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

FILE
fi

echo "Script once-as-root.sh Done"