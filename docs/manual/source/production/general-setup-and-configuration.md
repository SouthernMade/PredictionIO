General Setup and Configuration
---

In a production environment, event storage and training should be done on HA clusters rather than a single instance. To accomplish this, you will first need to create the following environments:

* Elasticsearch (1.4.0 or higher)
* HBase (0.98.6 or higher)
* Spark (1.3.0 or higher)

## Elasticsearch

To install an Elasticsearch cluster, perform the following on each instance:

```shell
sudo su - hadoop
mkdir elasticsearch && cd elasticsearch
wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.4.tar.gz
tar -zxvf elasticsearch-1.7.4.tar.gz
rm elasticsearch-1.7.4.tar.gz
wget http://download.elastic.co/hadoop/elasticsearch-hadoop-2.1.2.zip
unzip elasticsearch-hadoop-2.1.2.zip
rm elasticsearch-hadoop-2.1.2.zip
echo export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:/home/hadoop/elasticsearch/elasticsearch-hadoop-2.1.2 >> ~/.bashrc
```

On the master, configure as follows in `conf/elasticsearch.yml`:

```shell
node.master: true
node.data: false
path.logs: /var/log/elasticsearch
cluster.name: pio-elasticsearch
discovery.zen.ping.multicast.enabled: true
```

On the data nodes, configure as follows in `conf/elasticsearch.yml`:

```shell
node.master: false
node.data: true
path.data: /var/data/elasticsearch
path.logs: /var/log/elasticsearch
cluster.name: pio-elasticsearch
discovery.zen.ping.multicast.enabled: true
```

You should also visit https://www.elastic.co/guide/en/elasticsearch/reference/1.7/setup-configuration.html#system and configure the OS limits on each instance.

To install Elasticsearch as a system service:

```shell
gem2.0 install pleaserun
sudo /usr/local/bin/pleaserun --install -p sysv -v lsb-3.1 /home/hadoop/elasticsearch/elasticsearch-1.7.4/bin/elasticsearch
sudo service elasicsearch start
```

Test that your cluster is functional:

```shell
curl -XGET 'http://<PUBLIC_EC2_MASTER_INSTANCE_IP>:9200/_cluster/health?pretty=true'
```

### Elasticsearch on EC2

If you're using EC2, there are additional configuration options necessary for autodiscovery:

```shell
discovery.type: ec2
discovery.host: _ec2_
cloud.aws.region: {{YOUR_REGION}}
cloud.node.auto_attributes: true
network.host: _ec2_
http.host: _ec2_
```

You will also need the `cloud-aws` plugin:

```shell
/home/hadoop/elasicsearch/elasticsearch-1.7.4/bin/plugin install cloud-aws
```

## HBase

To install a HBase cluster, perform the following on each instance:

```shell
sudo su - hadoop
wget https://www.apache.org/dist/hbase/hbase-0.98.6-hadoop2.4-bin.tar.gz
mkdir -p /home/hadoop/hbase
tar -zxvf hbase-0.98.6-hadoop2.4-bin.tar.gz -C /home/hadoop/hbase
rm hbase-0.98.6-hadoop2.4-bin.tar.gz
```

Configuration of HBase is complex. It requires changes to both Hadoop and HBase config files, and will vary based on the amount of memory and number of disks your system has available.

Please see the [HBase example configuration](https://hbase.apache.org/0.94/book/example_config.html) for more details.

## Spark

To install a Spark cluster, perform the following on each instance:

```shell
sudo su - hadoop
wget http://d3kbcqa49mib13.cloudfront.net/spark-1.3.0-bin-hadoop2.4.tgz
mkdir -p /home/hadoop/spark
tar -zxvf spark-1.3.0-bin-hadoop2.4.tgz -C /home/hadoop/spark
rm spark-1.3.0-bin-hadoop2.4.tgz
```

On the master, add all of the slave IP addresses to `conf/slaves`:

```shell
123.34.56.78
123.34.567.89
```

Generate a password-less keypair on the master:

```shell
ssh-keygen -t rsa -N ""
```

Manually copy `~/.ssh/id_rsa*` from the master to each of the instances:

```shell
scp -r ~/.ssh/id_rsa* hadoop@123.34.56.78:~/.ssh/
```

On each instance, authorize the public key:

```shell
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

On the master, start the Spark cluster:

```shell
/home/hadoop/spark/spark-1.3.0-hadoop2.4-bin/sbin/start-all.sh
```
