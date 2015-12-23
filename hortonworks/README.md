# Hortonworks 快速安裝 #

原本研習營使用Azure平台提供的模擬機器，但是不知道是不是因為免費帳號的關係，網路連線使用者體驗很糟糕，索性直接在自己的機器上安裝Hortonworks虛擬機器，使用起來比較方便，也沒有網路品質的問題。

> 以下說明根據我實際安裝過程。

## 需求 ##

- 32-bit and 64-bit OS (Windows 7, Windows 8 and Mac OSX)
- Minimum 4GB RAM; 8Gb required to run Ambari and Hbase
- 安裝 VMware 或 VirtualBox
- 硬碟空間 20GB

## 下載 ##

請到[Hortonworks Sandbox on a VM](http://hortonworks.com/products/hortonworks-sandbox/#install)下載虛擬機器影像檔，檔案有點大(8G多)請耐心等候，下載後匯入VirtualBox。

等待下載時，建議瞄一下說明文件。
- [Install Guide for VirtualBox](http://hortonworks.com/wp-content/uploads/2015/07/Import_on_Vbox_7_20_2015.pdf)
- [Install Guild for VMware](http://hortonworks.com/wp-content/uploads/2015/07/Import_on_VMware_7_20_2015.pdf)

## 調整 ##

- 記憶大小：VirtualBox→設定值→系統→基本記憶體，設定為4G (如果你的記憶體足夠，給8G也無妨)
- 網路介面：VirtualBox→設定值→系統→網路→介面卡2，附加到「僅限主機」介面卡
