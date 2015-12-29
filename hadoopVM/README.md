# 打造自己的 Hadoop 虛擬機器

## 動機

之前從 Hortonworks 下載 hortonworks sandbox VM 影像檔，試玩發現裡面執行太多服務，不但佔硬碟也非常消耗CPU與記憶體，決定把之前安裝 ubuntu/trusty64 虛擬機、架設Hadoop相關服務的過程寫成筆記。

## 需求

- 安裝 [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- 安裝 [Vagrant](https://www.vagrantup.com/downloads.html)
- 記憶體 2G (要跑Spark)
- 硬碟空間 10G (以我的case，10G就夠用)

## 參考資料
- [Running Hadoop on Ubuntu Linux (Single-Node Cluster)](http://www.michael-noll.com/tutorials/running-hadoop-on-ubuntu-linux-single-node-cluster/)

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
```

## 安裝 Java SDK

先更新apt source list
```shell
$ sudo apt-get update
$ sudo apt-get install python-software-properties
$ sudo add-apt-repository ppa:ferramroberto/java
```

安裝ubunbu自帶的openjdk-7-jdk
```shell
$ sudo apt-get install -y openjdk-7-jdk
```

檢查安裝的版本
```shell
$ java -version
java version "1.7.0_91"
OpenJDK Runtime Environment (IcedTea 2.6.3) (7u91-2.6.3-0ubuntu0.14.04.1)
OpenJDK 64-Bit Server VM (build 24.91-b01, mixed mode)
```

## 新增Hadoop系統使用者

```shell
$ sudo addgroup hadoop
$ sudo adduser --ingroup hadoop adsctw
```

- 新增```hadoop```群組
- 新增```adsctw```使用者

## 設定ssh連線

Hadoop使用ssh存取遠端，即使是單機也需要連接```localhost```。

先切換到```adsctw```使用者，產生ssh public key，把來自localhost的連線變成不需密碼登入
```shell
$ su - adsctw
$ ssh-keygen -t rsa -P ""
$ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

測試一下，耶！登入不用密碼
```
$ ssh localhost
```

___
<<未完待續>>
