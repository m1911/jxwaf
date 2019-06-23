#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

set -e

#检测是否是root用户
if [ $(id -u) != "0" ]; then
	echo "错误：必须使用Root用户才能执行此脚本."
	exit 1
fi

read -p "请输入jxwaf_api_key:" JXWAF_API_KEY
if [[ ${JXWAF_API_KEY} = "" ]]; then
    exit 
elif [[ ${JXWAF_API_KEY} != "" ]]; then
    read -p "请输入jxwaf_api_password:" JXWAF_API_PASSWD
    if [[ ${JXWAF_API_PASSWD} = "" ]]; then
        exit
    fi
fi


yum install -y epel-release pcre-devel openssl-devel cmake make curl lua-devel gcc-c++ automake

tar zxvf openresty-1.15.8.1.tar.gz
tar zxvf libmaxminddb-1.3.2.tar.gz
tar zxvf aliyun-log-c-sdk-lite.tar.gz
tar zxvf curl-7.64.1.tar.gz

cd curl-7.64.1
make
make install

cd ../openresty-1.15.8.1
./configure --prefix=/opt/jxwaf && gmake && gmake install
mv /opt/jxwaf/nginx/conf/nginx.conf  /opt/jxwaf/nginx/conf/nginx.conf.bak
cp ../conf/nginx.conf /opt/jxwaf/nginx/conf/
cp ../conf/full_chain.pem /opt/jxwaf/nginx/conf/
cp ../conf/private.key /opt/jxwaf/nginx/conf/
mkdir -p /opt/jxwaf/nginx/conf/jxwaf
cp ../conf/jxwaf_config.json /opt/jxwaf/nginx/conf/jxwaf/
cp ../conf/GeoLite2-Country.mmdb /opt/jxwaf/nginx/conf/jxwaf/
cp -r ../lib/resty/jxwaf  /opt/jxwaf/lualib/resty/

cd ../libmaxminddb-1.3.2
./configure
make
cp src/.libs/libmaxminddb.so.0.0.7 /opt/jxwaf/lualib/libmaxminddb.so

cd ../aliyun-log-c-sdk-lite
cmake .
make
cp build/lib/liblog_c_sdk.so.2.0.0 /opt/jxwaf/lualib/liblog_c_sdk.so

sed -i 's/"waf_api_key": ""/"waf_api_key": "'$JXWAF_API_KEY'"/'  /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json
sed -i 's/"waf_api_password": ""/"waf_api_password": "'$JXWAF_API_PASSWD'"/'    /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json

/opt/jxwaf/nginx/sbin/nginx -t


