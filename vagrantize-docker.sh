#!/usr/bin/env bash

# Steps taken from: https://github.com/rofrano/vagrant-docker-provider/blob/master/Dockerfile.ubuntu
# Install packages needed for SSH and interactive OS
apt-get update
yes | unminimize
apt-get -y install \
		openssh-server \
		passwd \
		man-db \
		sudo \
		wget \
		vim-tiny 
apt-get -qq clean
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
useradd -m -G sudo -s /bin/bash vagrant
echo "vagrant:vagrant" | chpasswd
echo "vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
chmod 440 /etc/sudoers.d/vagrant

# Establish ssh keys for vagrant
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
wget https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh







