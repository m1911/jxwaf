FROM centos

#USER root
RUN yum install -y epel-release pcre-devel openssl-devel gcc cmake make g++ curl lua-devel gcc-c++ automake  git \
	&& cd /tmp \
    && git clone https://github.com/m1911/jxwaf.git \
    && cd jxwaf \
    && tar zxvf openresty-1.15.8.1.tar.gz \
    && tar zxvf libmaxminddb-1.3.2.tar.gz \
    && tar zxvf aliyun-log-c-sdk-lite.tar.gz \
    && tar zxvf curl-7.64.1.tar.gz \
    && cd curl-7.64.1 \
    && make \
    && make install \
    && cd ../openresty-1.15.8.1 \
    && ./configure --prefix=/opt/jxwaf --with-http_v2_module && gmake && gmake install \
    && mv /opt/jxwaf/nginx/conf/nginx.conf  /opt/jxwaf/nginx/conf/nginx.conf.bak \
    && cp ../conf/nginx.conf /opt/jxwaf/nginx/conf/ \
    && cp ../conf/full_chain.pem /opt/jxwaf/nginx/conf/ \
    && cp ../conf/private.key /opt/jxwaf/nginx/conf/ \
    && mkdir -p /opt/jxwaf/nginx/conf/jxwaf \
    && cp ../conf/jxwaf_config.json /opt/jxwaf/nginx/conf/jxwaf/ \
    && cp ../conf/GeoLite2-Country.mmdb /opt/jxwaf/nginx/conf/jxwaf/ \
    && cp -r ../lib/resty/jxwaf  /opt/jxwaf/lualib/resty/ \
    && cd ../libmaxminddb-1.3.2 \
    && ./configure \
    && make \
    && cp src/.libs/libmaxminddb.so.0.0.7 /opt/jxwaf/lualib/libmaxminddb.so \
    && cd ../aliyun-log-c-sdk-lite \
    && cmake . \
    && make \
    && cp build/lib/liblog_c_sdk.so.2.0.0 /opt/jxwaf/lualib/liblog_c_sdk.so \
    && /opt/jxwaf/nginx/sbin/nginx -t

EXPOSE 80 443

CMD sed -i 's/"waf_api_key": ""/"waf_api_key": "'$JXWAF_API_KEY'"/'  /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json \
    && sed -i 's/"waf_api_password": ""/"waf_api_password": "'$JXWAF_API_PASSWD'"/'    /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json  \
    && sed -i 's#"waf_update_website": "http://update2.jxwaf.com/waf_update"#"waf_update_website": "'$WAF_UPDATE_WEBSITE'"#'    /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json  \
    && cat /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json \
    && /opt/jxwaf/nginx/sbin/nginx \
    && tail -f /opt/jxwaf/nginx/logs/error.log

#COPY  ./setenv.sh  .
#CMD sh setenv.sh  $JXWAF_API_KEY   $JXWAF_API_PASSWD
#ENTRYPOINT ["/bin/bash","setenv.sh"]
