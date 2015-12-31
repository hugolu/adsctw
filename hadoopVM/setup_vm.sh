#!/bin/bash

mkdir adsctw
cd adsctw

vagrant init ubuntu/trusty64
cp -f ../Vagrantfile .

vagrant up
vagrant ssh
