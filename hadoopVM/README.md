# 打造自己的 Hadoop 虛擬機器

## 動機

之前從 Hortonworks 下載 [hortonworks sandbox](http://hortonworks.com/products/hortonworks-sandbox/#install) VM 影像檔，試玩發現裡面執行太多服務，不但肥大也很耗資源，決定把之前安裝 ubuntu/trusty64 虛擬機、架設Hadoop相關服務的過程寫成筆記。

這篇文章沒有包山包海的企圖，也沒有想要真正架設一個Hadoop Cluster，只想單存弄一個簡易的單機偽分佈式系統(Pseudo-Distributed Mode)，可以讓自己在上面複習課堂上除了Azure Machine Learning、HDinsight之外的課程。要建置這樣的環境，需要的服務包含：
- Hadoop/HDFS
- Hive
- MySQL
- Sqoop
- Scala
- Spark

## 需求

- 安裝 [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- 安裝 [Vagrant](https://www.vagrantup.com/downloads.html)
- 記憶體 2G (要跑Spark)
- 硬碟空間 10G (以我的case，10G就夠用)

## 安裝、設定、連接 VM

以下動作在我的 MacBookPro 使用 iTerm 操作，只列出相關指令，不顯示安裝過程終端機輸出的訊息。

創建adsctw目錄，把VM安裝在此
```shell
$ mkdir adsctw
$ cd adsctw
```

下載vagrant box
```shell
$ vagrant init ubuntu/trusty64
```

啟動前修改VM記憶體配置
```shell
$ vi Vagrantfile
```
```
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end
```

啟動VM，如果你有安裝多個虛擬機軟體，請加上```--provider virtualbox```選項指定virtualbox
```shell
$ vagrant up
```

啟動後使用ssh連線登入，登入者名稱為```vagrant```
```shell
$ vagrant ssh
vagrant@vagrant-ubuntu-trusty-64:~$
```

## APT

安裝套件有兩種方式，一個是下載source自行編譯、另一個是使用套件管理工具，除非你想修改(hack)套件內容不然一般會選擇使用管理套件工具。為了讓自己生活愉快，我在這份說明文件中使用[APT](https://en.wikipedia.org/wiki/Advanced_Packaging_Tool)安裝工具與服務程式。

更新apt source list，並安裝待需要用到的工具。
```shell
$ sudo apt-get update
$ sudo apt-get install -y git unzip tree
```

## User

創建有執行Hadoop/HDFS權限的使用者```hadoop```，把它加入```sudo```群組，這樣就能使用```root```權限執行指令。
```shell
$ sudo useradd -m hadoop -s /bin/bash
$ sudo passwd hadoop
$ sudo adduser hadoop sudo
```

OK！接下來所有動作換成```hadoop```身份來操作。
```shell
$ sudo su - hadoop
```

Hadoop使用ssh存取遠端，即使是單機也需要連接```localhost```。接下來，認證自己的ssh public key，以便將來可以不需使用密碼登入。
```shell
$ ssh-keygen -t rsa
$ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

測試一下，歐耶～確定登入不用密碼後離開
```
$ ssh localhost
$ exit
```

## Java SDK

安裝ubunbu自帶的openjdk-7-jdk
```shell
$ sudo apt-get install -y openjdk-7-jdk
```

設定環境變數
```shell
$ vim ~/.bashrc
```
```
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
```

檢查安裝的版本
```shell
$ java -version
```

## 安裝 Hadoop
參考資料
- [Running Hadoop on Ubuntu Linux (Single-Node Cluster)](http://www.michael-noll.com/tutorials/running-hadoop-on-ubuntu-linux-single-node-cluster/)

到[Apache Download Mirrors](http://www.apache.org/dyn/closer.cgi/hadoop/core)下載最新的hadoop package
```shell
$ cd /tmp
$ wget http://ftp.tc.edu.tw/pub/Apache/hadoop/core/hadoop-2.7.1/hadoop-2.7.1.tar.gz
```

安裝到```/usr/local```
```shell
$ cd /usr/local
$ sudo tar xzf /tmp/hadoop-2.7.1.tar.gz
$ sudo chown -R adsctw:hadoop hadoop-2.7.1
$ sudo ln -sf hadoop-2.7.1 hadoop
```
___
<<未完待續>>
