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

啟動後使用ssh連線登入，登入者名稱為 **vagrant**
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

## MySQL

Hadoop資料可能來自傳統結構化資料庫，第一天有課程教導如何把紀錄從MySQL遷移到Hive上。So，安裝Hadoop之前，先把MySQL安裝好。

安裝Ubuntu自帶的mysql-server，使用下面指令會一併安裝mysql-server、mysql-client、mysql-common。安裝過程會詢問**root**密碼，隨便打一個方便記憶的字串即可。
```shell
$ sudo apt-get install -y mysql-server
```

創建一個操作資料庫的使用者，課程預設帳號/密碼為**hive**/**hive**。先使用**root**身份登入登入mysql shell，看到提示符號由```$```變成```mysql>```，開始新增使用者。
```shell
$ mysql -uroot -p
```
```sql
mysql> INSERT INTO mysql.user(host,user,password) VALUES ('%','hive',password('hive'));
mysql> GRANT ALL ON *.* TO 'hive'@localhost IDENTIFIED BY 'hive' WITH GRANT OPTION;
mysql> FLUSH PRIVILEGES;
mysql> QUIT;
```

測試安裝是否成功
```shell
$ mysql -uhive -phive -e "select 1+1"
```

## User

創建有執行Hadoop/HDFS權限的使用者**hadoop**，把它加入**sudo**群組，這樣就能使用**root**權限執行指令。
```shell
$ sudo useradd -m hadoop -s /bin/bash
$ sudo passwd hadoop
$ sudo adduser hadoop sudo
```

OK！接下來所有動作換成**hadoop**身份來操作。
```shell
$ sudo su - hadoop
```

Hadoop使用ssh存取遠端，即使是單機也需要連接localhost。接下來，認證自己的ssh public key，以便將來可以不需使用密碼登入。
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

安裝Ubuntu自帶的openjdk-7-jdk
```shell
$ sudo apt-get install -y openjdk-7-jdk
```

設定環境變數，修改```~/.bashrc``` (ps.以下有關文件修改皆使用vim操作)
```shell
$ vim ~/.bashrc
```

加入以下內容
```
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
```

檢查安裝的版本
```shell
$ java -version
```

## Hadoop/HDFS
參考資料
- [Hadoop安装配置简略教程](http://www.powerxing.com/install-hadoop-simplify/)
- [Running Hadoop on Ubuntu Linux (Single-Node Cluster)](http://www.michael-noll.com/tutorials/running-hadoop-on-ubuntu-linux-single-node-cluster/)
- [Hadoop: Setting up a Single Node Cluster](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html)

到[Apache Download Mirrors](http://www.apache.org/dyn/closer.cgi/hadoop/core)下載最新的hadoop package，解壓縮後搬移到```/usr/local```目錄之下。
```shell
$ wget http://ftp.tc.edu.tw/pub/Apache/hadoop/core/hadoop-2.7.1/hadoop-2.7.1.tar.gz
$ tar zxf hadoop-2.7.1.tar.gz
$ sudo mv hadoop-2.7.1 /usr/local/hadoop
```

設定環境變數，修改```~/.bashrc```加入以下內容
```
export HADOOP_HOME=/usr/local/hadoop
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export CLASSPATH=$CLASSPATH:$(hadoop classpath)
```

設定 hadoop core-site，修改```/usr/local/hadoop/etc/hadoop/core-site.xml```內容
```
<configuration>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>file:/usr/local/hadoop/tmp</value>
        <description>Abase for other temporary directories.</description>
    </property>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
```

設定 hadoop hdfs-site，修改```/usr/local/hadoop/etc/hadoop/hdfs-site.xml```內容
```
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:/usr/local/hadoop/tmp/dfs/name</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:/usr/local/hadoop/tmp/dfs/data</value>
    </property>
</configuration>
```

設定hadoop環境變數，修改```/usr/local/hadoop/etc/hadoop/hadoop-env.sh```內容
```
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
```

格式化HDFS檔案系統
```shell
$ hdfs namenode -format
```

啟動HDFS服務，並檢視那些服務被啟動
```shell
$ start-dfs.sh
$ jps
```

測試 HDFS/MapReduce 功能是否正常
```shell
$ hadoop fs -mkdir -p /user/hadoop
$ hadoop fs -mkdir input
$ hadoop fs -put /usr/local/hadoop/etc/hadoop/*.xml input
$ hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar grep input output 'dfs[a-z.]+'
$ hadoop fs -cat output/*
```

## Hive
參考資料
- [Apache Hive Getting Started](https://cwiki.apache.org/confluence/display/Hive/GettingStarted)

到[Apache Download Mirrors](http://www.apache.org/dyn/closer.cgi/hive/)下載最新的hive package，解壓縮後搬移到```/usr/local```目錄之下。
```shell
$ wget http://ftp.tc.edu.tw/pub/Apache/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz
$ tar zxf apache-hive-1.2.1-bin.tar.gz -C /usr/local/
$ sudo mv apache-hive-1.2.1-bin /usr/local/hive
```

設定環境變數，修改```~/.bashrc```加入以下內容
```
export HIVE_HOME=/usr/local/hive
export PATH=$PATH:$HIVE_HOME/bin
```

測試 Hive 功能是否正常
```shell
$ hive -e "select 1+1"
```
___
<<未完待續>>
