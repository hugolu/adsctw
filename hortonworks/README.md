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

### 啟動前設定 ###
- 記憶大小：VirtualBox→設定值→系統→基本記憶體，設定為4G (如果你的記憶體足夠，給8G也無妨)
- 網路介面：VirtualBox→設定值→系統→網路→介面卡2，附加到「僅限主機」介面卡

### 啟動後設定 ###
系統啟動後，使用VirtualBox VM使用者操作介面登入系統
- user: root
- pass: hadoop

登入後，修改密碼，先給個複雜的密碼 (CentOS改密碼很龜毛)，然後再改回簡單容易記憶的密碼 XD
```
# passwd
Changing password for user root.
New password:
Retype new password:
passwd: all authentication tokens updated successfully.
```

設定一般權限的使用者帳號 (使用這個帳號登入練習)
```
# adduser adsctw
# passwd adsctw
Changing password for user adsctw.
New password:
Retype new password:
passwd: all authentication tokens updated successfully.
```

設定網路，如果要讓外面的世界(Host OS)可以連接虛擬機器上的世界(Guest OS)，我通常會加一個```host-only network interface```，這樣就算沒有網路也可以透過內部的網域連進去做實驗。
在VirtualBox上新增一個「僅限主機」介面卡之後，在Host OS會多一張虛擬的網路卡，以我為例，看到的網卡IP是192.168.33.1，所以Guest OS裡面的網路介面2設定方法為
```
# vi /etc/sysconfig/network-scripts/ifcfg-eth1
```
加入以下內容
```
DEVICE="eth1"

IPV6INIT="no"
ONBOOT="yes"
TYPE="Ethernet"

NM_CONTROLLED=no
PEERDNS=no

IPADDR="192.168.33.11"
NETMASK="255.255.255.0"
```
設定好之後，執行以下指令讓設定發生
```
# service network restart
```

好吧，如果覺得這樣設定有難度，使用以下方式也可以。但這樣設定只是暫時的，下次重新開機設定會消失，需要重新設定一次。
```
# ifconfig eth1 192.168.33.11
```

設定完成就可以透過[putty](http://www.chiark.greenend.org.uk/~sgtatham/putty/)或[iTerm](https://www.iterm2.com/)連接進入Hortonworks
```
$ ssh adsctw@192.168.33.11
adsctw@192.168.33.11's password:
$
```
---
## 補充 ##

使用```adsctw```登入系統，發現這個帳號沒有存取hdfs的權限，嘗試透過hortonworks網頁管理介面修改使用者權限，弄了半小時搞不定(摔筆)。幹脆土炮硬幹，透過root帳號登入系統修改一下hdfs設定
```
$ vi /etc/hadoop/2.3.2.0-2950/0/hdfs-site.xml
```

修改內容，把```false```改成```true```
```
<property>
  <name>dfs.permissions.enabled</name>
  <value>true</value>
</property>
```

然後透過管理介面 http://192.168.33.11:8080 (user:admin, pass:admin)，選擇HDFS→Service Actions→Restart All。等待一兩分鐘後，服務重啟完成，```adsctw```就可以亂搞hdfs了 XD
