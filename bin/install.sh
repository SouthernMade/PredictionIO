#!/usr/bin/env bash

# Copyright 2015 TappingStone, Inc.
# Modified by Justin Ramos (justin@southernmade.co)
#
# This script will install PredictionIO onto your computer!
#
# Documentation: http://docs.prediction.io
#
# License: http://www.apache.org/licenses/LICENSE-2.0

OS=`uname`
PIO_VERSION=0.9.5
SPARK_VERSION=1.5.2
ELASTICSEARCH_VERSION=2.1.1
HBASE_VERSION=1.0.2
HADOOP_VERSION=2.4
PIO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
USER_PROFILE=$HOME/.profile
TEMP_DIR=/tmp

echo -e "\033[1;32mWelcome to PredictionIO $PIO_VERSION!\033[0m"

# Detect OS
if [[ "$OS" = "Darwin" ]]; then
  echo "Mac OS detected!"
  SED_CMD="sed -i ''"
elif [[ "$OS" = "Linux" ]]; then
  echo "Linux OS detected!"
  SED_CMD="sed -i"
else
  echo -e "\033[1;31mYour OS $OS is not yet supported for automatic install :(\033[0m"
  echo -e "\033[1;31mPlease do a manual install!\033[0m"
  exit 1
fi

if [[ $USER ]]; then
  echo "Using user: $USER"
else
  echo "No user found - this is OK!"
fi

pio_dir=${PIO_DIR}
vendors_dir=${pio_dir}/vendors
spark_dir=${vendors_dir}/spark-${SPARK_VERSION}
elasticsearch_dir=${vendors_dir}/elasticsearch-${ELASTICSEARCH_VERSION}
hbase_dir=${vendors_dir}/hbase-${HBASE_VERSION}
zookeeper_dir=${vendors_dir}/zookeeper

echo "--------------------------------------------------------------------------------"
echo "You are going to install PredictionIO to: $pio_dir"
echo -e "Vendor applications will go in: $vendors_dir\n"
echo "Spark: $spark_dir"
echo "Elasticsearch: $elasticsearch_dir"
echo "HBase: $hbase_dir"
echo "ZooKeeper: $zookeeper_dir"
echo "--------------------------------------------------------------------------------"

mkdir -p $PIO_DIR
mkdir -p $vendors_dir

# Try to find JAVA_HOME
echo "Locating JAVA_HOME..."
if [[ "$OS" = "Darwin" ]]; then
  JAVA_VERSION=`echo "$(java -version 2>&1)" | grep "java version" | awk '{ print substr($3, 2, length($3)-2); }'`
  JAVA_HOME=`/usr/libexec/java_home`
elif [[ "$OS" = "Linux" ]]; then
  JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
fi
echo "JAVA_HOME is now set to: $JAVA_HOME"

if [ -n "$JAVA_VERSION" ]; then
  echo "Your Java version is: $JAVA_VERSION"
fi

# PredictionIO
echo -e "\033[1;36mStarting PredictionIO setup in:\033[0m $pio_dir"
cd ${TEMP_DIR}

if [[ $USER ]]; then
  chown -R $USER ${pio_dir}
fi

echo "Updating ~/.profile to include: $pio_dir"
PATH=$PATH:${pio_dir}/bin
echo "export PATH=\$PATH:$pio_dir/bin" >> ${USER_PROFILE}

##################################
# Spark
##################################

echo -e "\033[1;36mStarting Spark setup in:\033[0m $spark_dir"
if [[ ! -e spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz ]]; then
  echo "Downloading Spark..."
  aws s3 cp s3://southernmade-analytics-environments/vendor/spark/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz .
fi
tar zxf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
rm -rf ${spark_dir}
mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} ${spark_dir}

echo -e "\033[1;32mSpark setup done!\033[0m"

##################################
# Elasticsearch
##################################

echo -e "\033[1;36mStarting Elasticsearch setup in:\033[0m $elasticsearch_dir"
if [[ ! -e elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz ]]; then
  echo "Downloading Elasticsearch..."
  aws s3 cp s3://southernmade-analytics-environments/vendor/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz .
fi
tar zxf elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz
rm -rf ${elasticsearch_dir}
mv elasticsearch-${ELASTICSEARCH_VERSION} ${elasticsearch_dir}

echo "Updating: $elasticsearch_dir/config/elasticsearch.yml"
echo 'network.host: 127.0.0.1' >> ${elasticsearch_dir}/config/elasticsearch.yml

echo -e "\033[1;32mElasticsearch setup done!\033[0m"

##################################
# HBase
##################################

echo -e "\033[1;36mStarting HBase setup in:\033[0m $hbase_dir"
if [[ ! -e hbase-${HBASE_VERSION}-bin.tar.gz ]]; then
  echo "Downloading HBase..."
  aws s3 cp s3://southernmade-analytics-environments/vendor/hbase/hbase-${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz .
fi
tar zxf hbase-${HBASE_VERSION}-bin.tar.gz
rm -rf ${hbase_dir}
mv hbase-${HBASE_VERSION} ${hbase_dir}

if [[ $HBASE_ZOOKEEPER_QUORUM ]]; then
  echo "Creating custom site in: $hbase_dir/conf/hbase-site.xml"
  cat <<EOT > ${hbase_dir}/conf/hbase-site.xml
  <configuration>
    <property>
      <name>hbase.zookeeper.quorum</name>
      <value>${HBASE_ZOOKEEPER_QUORUM}</value>
    </property>
    <property>
      <name>hbase.zookeeper.property.dataDir</name>
      <value>${zookeeper_dir}</value>
    </property>
  </configuration>
EOT
else
  echo "Creating default site in: $hbase_dir/conf/hbase-site.xml"
  cat <<EOT > ${hbase_dir}/conf/hbase-site.xml
  <configuration>
    <property>
      <name>hbase.rootdir</name>
      <value>file://${hbase_dir}/data</value>
    </property>
    <property>
      <name>hbase.zookeeper.property.dataDir</name>
      <value>${zookeeper_dir}</value>
    </property>
  </configuration>
EOT
fi

echo "Updating: $hbase_dir/conf/hbase-env.sh to include $JAVA_HOME"
${SED_CMD} "s|# export JAVA_HOME=/usr/java/jdk1.6.0/|export JAVA_HOME=$JAVA_HOME|" ${hbase_dir}/conf/hbase-env.sh

echo -e "\033[1;32mHBase setup done!\033[0m"

##################################
# Finalize install
##################################

echo "Updating permissions on: $vendors_dir"

if [[ $USER ]]; then
  chown -R $USER ${vendors_dir}
fi

echo -e "\033[1;32mInstallation done!\033[0m"

echo "--------------------------------------------------------------------------------"
echo -e "\033[1;32mInstallation of PredictionIO $PIO_VERSION complete!\033[0m"
echo -e "\033[1;32mPlease follow documentation at http://docs.prediction.io/start/download/ to download the engine template based on your needs\033[0m"
echo -e
echo -e "\033[1;33mCommand Line Usage Notes:\033[0m"
echo -e "To start PredictionIO and dependencies, run: '\033[1mpio-start-all\033[0m'"
echo -e "To check the PredictionIO status, run: '\033[1mpio status\033[0m'"
echo -e "To train/deploy engine, run: '\033[1mpio [train|deploy|...]\033[0m' commands"
echo -e "To stop PredictionIO and dependencies, run: '\033[1mpio-stop-all\033[0m'"
echo -e ""
echo -e "Please report any problems to: \033[1;34msupport@prediction.io\033[0m"
echo "--------------------------------------------------------------------------------"
