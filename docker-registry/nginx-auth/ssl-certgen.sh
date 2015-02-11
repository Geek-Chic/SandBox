#!/bin/bash

# File Name:gen_cert.sh
# Description:
# @Author: evil
# Created Time:Tue 10 Feb 2015 04:53:58 PM CST
if [[ ! -d nginx-auth  ]];then
    mkdir -p nginx-auth
fi
cd nginx-auth
sudo rm -v ca-key.pem ca.pem ca.srl extfile.cnf key.pem server-cert.pem server-key.pem
#生成ca.srl
sudo echo '01' > ca.srl
#生成根密钥
sudo openssl genrsa -aes256 -out ca-key.pem 2048
#生成根证书
sudo openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
echo "[INFO] Make sure that 'Common Name'(i.e.,server FQDN or YOUR name) matches the hostname you will use to connect to Docker:$HOST"
#为nginx web生成ssl密钥
sudo openssl genrsa -out server-key.pem 2048
#为nginx生成证书签署请求
sudo openssl req -subj "/CN=registry.com" -new -key server-key.pem -out server.csr
#用CA给公钥签名
sudo openssl x509 -req -days 365 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem
#生成客户端密钥
sudo openssl genrsa -out key.pem 2048
#生成客户端签署请求
sudo openssl req -subj '/CN=client' -new -key key.pem -out client.csr
#客户端签名
sudo echo extendedKeyUsage = clientAuth > extfile.cnf
sudo openssl x509 -req -days 365 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile.cnf
#权限设置
sudo chmod -v 0400 ca-key.pem key.pem server-key.pem
sudo chmod -v 0444 ca.pem server-cert.pem cert.pem
#删除中间无用
sudo rm -v client.csr server.csr
#生成访问密码
htpasswd -b -c -d docker-registry.htpasswd evil admin
sudo mkdir -p /etc/docker/certs.d/registry.com
sudo cp ca.pem /etc/docker/certs.d/registry.com
