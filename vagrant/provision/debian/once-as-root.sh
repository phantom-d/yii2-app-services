#!/usr/bin/env bash

#== Import script args ==

app_path=$(echo "$1")
timezone=$(echo "$2")

#== Bash helpers ==

function info {
  echo " "
  echo "--> $1"
  echo " "
}

#== Provision script ==

info "Provision-script user: `whoami`"

export DEBIAN_FRONTEND=noninteractive

info "Configure timezone"
echo ${timezone} | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

info "Update OS software"
echo "deb http://packages.dotdeb.org $(lsb_release -sc) all" | tee /etc/apt/sources.list.d/dotdeb.list
echo "deb-src http://packages.dotdeb.org $(lsb_release -sc) all" | tee -a /etc/apt/sources.list.d/dotdeb.list
wget --quiet -O - https://www.dotdeb.org/dotdeb.gpg | apt-key add -

apt-get update -qq
apt-get upgrade -y
info "Done!"

info "Install additional software"
apt-get install -y git mc htop gdebi locales-all mytop

systemctl unmask nginx.service
systemctl enable nginx.service
apt-get autoremove -y
info "Done!"

info "Configure locales"
localectl set-locale LANG=ru_RU.utf8

info "Create bash-alias for root user"
echo 'alias app="cd '${app_path}'"' | tee /root/.bash_aliases
echo 'alias logs="cd '${app_path}'/vgrant/logs"' | tee -a /root/.bash_aliases
info "Done!"

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

echo "Script `basename $0` Done"
