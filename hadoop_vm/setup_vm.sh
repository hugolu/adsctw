#!/bin/bash

## setup vm
vagrant init ubuntu/trusty64
cp -f my.Vagrantfile Vagrantfile

## power up VM
vagrant up

## login VM
vagrant ssh
