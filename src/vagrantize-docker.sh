#!/usr/bin/env bash

#set -xe

source ./lib/getoptions.bash
source ./lib/bashtdlib/bashtdlib.bash

does_user_exist() {
  local user
  bashtdlib:store_arg user 1
  if ! id "$user" >&1 >/dev/null; then
    return 1
  fi
}

parser_definition() {
        setup   REST help:usage \
                -- "Usage: ${2##*/} [options...] [arguments...]" ''
        msg -- 'Options:'
        param   USERNAME    -u    --user init:"=vagrant"  -- "Custom user to user for Vagrant access"
        param   PASSWORD    -p    --password init:"= "  -- "password for custom user. Will be ignored unless --user is also set"
        disp    :usage  -h    --help
        disp    VERSION       --version
}

eval "$(getoptions parser_definition parse "$0") exit 1"
parse "$@"
eval "set -- $REST"

export DEBIAN_FRONTEND=noninteractive


# Steps taken from: https://github.com/rofrano/vagrant-docker-provider/blob/master/Dockerfile.ubuntu
# Install packages needed for SSH and interactive OS
bashtdlib:exit_on_error -- "Unable to run apt-get update" bashtdlib:sudo_if_not_root --password="$PASSWORD" -- apt-get -y update
# Install apt-utils
bashtdlib:exit_on_error -- "Unable to install apt-utils" bashtdlib:sudo_if_not_root --password="$PASSWORD" -- apt-get install -y apt-utils
bashtdlib:exit_on_error --skip-if-contains='dpkg-query: error: --search needs at least one file name pattern argument' -- 'Unable to unminimize' bashtdlib:sudo_if_not_root --password="$PASSWORD" -- bash -c 'set -o pipefail; yes | DEBIAN_FRONTEND=noninteractive unminimize'
bashtdlib:exit_on_error -- 'Unable to install packages' bashtdlib:sudo_if_not_root --password="$PASSWORD" -- apt-get -y install \
		openssh-server \
		passwd \
		man-db \
		sudo \
		wget \
		vim-tiny 
echo "Installed packages!!!!!!!!!!"
bashtdlib:exit_on_error -- "Unable to run apt-get" apt-get -qq clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Enable systemd (from Matthew Warman's mcwarman/vagrant-provider)
# TODO: Figure out why this line only runs in sh but not bash
/bin/sh -c '(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done)'
rm -f /lib/systemd/system/multi-user.target.wants/*
rm -f /etc/systemd/system/*.wants/*
rm -f /lib/systemd/system/local-fs.target.wants/*
rm -f /lib/systemd/system/sockets.target.wants/*udev*
rm -f /lib/systemd/system/sockets.target.wants/*initctl*
rm -f /lib/systemd/system/basic.target.wants/*
rm -f /lib/systemd/system/anaconda.target.wants/*

# Enable ssh for vagrant
systemctl enable ssh.service

# Create the vagrant user
if ! does_user_exist "$USERNAME"; then
  useradd -m -G sudo -s /bin/bash "$USERNAME" 
fi
echo "$USERNAME:vagrant" | sudo chpasswd
bash -c "echo '$USERNAME ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant"
chmod 440 /etc/sudoers.d/vagrant

# Establish ssh keys for vagrant
mkdir -p "/home/$USERNAME/.ssh"
chmod 700 "/home/$USERNAME/.ssh"
wget https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -O "/home/$USERNAME/.ssh/authorized_keys"
chmod 600 "/home/$USERNAME/.ssh/authorized_keys"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"
