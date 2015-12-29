# Hadoop 虛擬機器

## 動機

之前從 Hortonworks 下載 hortonworks sandbox VM 影像檔，試玩發現裡面執行太多服務，不但佔硬碟也非常消耗CPU與記憶體，決定把之前安裝 ubuntu/trusty64 虛擬機、架設Hadoop相關服務的過程寫成筆記。

## 需求

- 安裝 [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- 安裝 [Vagrant](https://www.vagrantup.com/downloads.html)
- 記憶體 2G (要跑Spark)
- 硬碟空間 10G (以我的case，10G就夠用)

## 安裝、設定VM

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
