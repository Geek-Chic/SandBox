#!/bin/bash

# File Name:gen_cert.sh
# Description:
# @Author: evil
# Created Time:Tue 10 Feb 2015 04:53:58 PM CST
if [[ ! -d nginx-auth  ]];then
    mkdir -p nginx-auth
fi
#生成ca.srl
echo 01>ca.srl
#生成根密钥
sudo openssl genrsa -des3 -out ca-key.pem 2048
#生成根证书
sudo openssl req -new -x509 -days 3650 -key ca-key.pem -out ca.pem
#为nginx web生成ssl密钥
sudo openssl genrsa -des3 -out server-key.pem 2048
#为nginx生成证书签署请求
sudo openssl x509 -req -days 365 -in server.csr -CA ca.pem -CAkey ca-key.pem -out server-cert.pem
#移除server-key.pem密码
sudo openssl rsa -in server-key.pem -out server-key.pem
#生成访问密码
htpasswd -b -c -d docker-registry.htpasswd evil admin
