# 打造自己的 Hadoop 虛擬機器

## 動機

之前從 Hortonworks 下載 hortonworks sandbox VM 影像檔，試玩發現裡面執行太多服務，不但佔硬碟也非常消耗CPU與記憶體，決定把之前安裝 ubuntu/trusty64 虛擬機、架設Hadoop相關服務的過程寫成筆記。

## 需求

- 安裝 [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- 安裝 [Vagrant](https://www.vagrantup.com/downloads.html)
- 記憶體 2G (要跑Spark)
- 硬碟空間 10G (以我的case，10G就夠用)

## 安裝、設定、連接 VM

以下動作在我的 MacBookPro 使用 iTerm 操作。

創建adsctw目錄，把VM安裝在此
```shell
$ mkdir adsctw
$ cd adsctw
```

下載vagrant box
```shell
$ vagrant init ubuntu/trusty64
```

啟動前修改```Vagrantfile```裡面記憶體的配置
```shell
$ vi Vagrantfile
```
```
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end
```

第一次啟動
```shell
$ vagrant up --provider virtualbox
```

啟動後，使用ssh連線登入
```shell
$ vagrant ssh
Welcome to Ubuntu 14.04.3 LTS (GNU/Linux 3.13.0-66-generic x86_64)

 * Documentation:  https://help.ubuntu.com/

  System information as of Tue Dec 29 08:38:18 UTC 2015

  System load:  0.91              Processes:           82
  Usage of /:   2.8% of 39.34GB   Users logged in:     0
  Memory usage: 6%                IP address for eth0: 10.0.2.15
  Swap usage:   0%

  Graph this data and manage this system at:
    https://landscape.canonical.com/

  Get cloud support with Ubuntu Advantage Cloud Guest:
    http://www.ubuntu.com/business/services/cloud

0 packages can be updated.
0 updates are security updates.


vagrant@vagrant-ubuntu-trusty-64:~$
```

整個系統只有1.2G，乾乾淨淨要什麼沒什麼 XD
```shell
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        40G  1.2G   37G   3% /
none            4.0K     0  4.0K   0% /sys/fs/cgroup
udev            997M   12K  997M   1% /dev
tmpfs           201M  348K  200M   1% /run
none            5.0M     0  5.0M   0% /run/lock
none           1001M     0 1001M   0% /run/shm
none            100M     0  100M   0% /run/user
vagrant         112G   79G   34G  70% /vagrant
```
