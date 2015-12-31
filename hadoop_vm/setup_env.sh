#!/bin/bash

## setup apt
sudo apt-get update
sudo apt-get -y install unzip tree

## add User
sudo useradd -m hadoop -s /bin/bash
echo -e "hadoop\nhadoop" | sudo passwd hadoop
sudo adduser hadoop sudo

## hack sudoers
sudo cp -f /vagrant/sudoers /etc/

## change user
sudo su - hadoop
