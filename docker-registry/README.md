##安装Docker Registry
1. 如果是内网，则可以不需要安装验证
service docker stop  
nohup docker -H unix:///var/run/docker.sock --insecure-registry 127.0.0.1:5000 -d &
2. 使用安装验证使用私有库，使用nginx做代理 ，增加SSL/TLS验证
这里需要创建两个Docker Container,一个是docker-registry,别一个是docker-nginx-auth-registry 做安全验证

###Requirement
####证书
1.如果自己已经申请了证书，则可以跳过ssl-certgen.sh脚本中的自建证书，直接开始创建服务器密钥和签名
2.如果没有证书，直接运行ssl-certgen.sh脚本，会创建证书和服务器/客户端密钥
创建证书
#####生成ca.srl
sudo echo '01' > ca.srl
#####生成根密钥
sudo openssl genrsa -aes256 -out ca-key.pem 2048
#####生成根证书
sudo openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
echo "[INFO] Make sure that 'Common Name'(i.e.,server FQDN or YOUR name) matches the hostname you will use to connect to Docker:$HOST"
#####为nginx web生成ssl密钥
sudo openssl genrsa -out server-key.pem 2048
#####为nginx生成证书签署请求
sudo openssl req -subj "/CN=registry.com" -new -key server-key.pem -out server.csr
#####用CA给公钥签名
sudo openssl x509 -req -days 365 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem
#####生成客户端密钥
sudo openssl genrsa -out key.pem 2048
#####生成客户端签署请求
sudo openssl req -subj '/CN=client' -new -key key.pem -out client.csr
#####客户端签名
sudo echo extendedKeyUsage = clientAuth > extfile.cnf
sudo openssl x509 -req -days 365 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile.cnf
#####权限设置
sudo chmod -v 0400 ca-key.pem key.pem server-key.pem
sudo chmod -v 0444 ca.pem server-cert.pem cert.pem
#####删除中间无用
sudo rm -v client.csr server.csr
#####生成访问密码
htpasswd -b -c -d docker-registry.htpasswd evil admin
sudo mkdir -p /etc/docker/certs.d/registry.com
sudo cp ca.pem /etc/docker/certs.d/registry.com
###Tips:
  1. x509: certificate signed by unknown authority
这是因为我们创建的证书是不可信的，所以我们要在客户机的信息信任证书中添加。

  MAC:打开Keychain Access -》File->Import items(Ctrl+shift+I)->选择ca.pem-》导入后在右键，Get Info   中，把trust里所有选项改为Always Trust
  
  Linux:
    Centos:sudo cp /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-bundle.crt.bk
           sudo sh -c "cat ${CAPTH}/ca.pem >> ca-bundle.crt"
   做完后最好重启一个docker,sudo service docker restart,然后重新运行registry和nginx-auth容器

  2. 什么cannot validate cert because it doesnt contain any IP SANS

   这是因为我们在证书中绑定的Common Name为Host，要求是域名，不要用IP，这里我们设定为registry.com,然后在/etc/hosts里修改为我自已的ip，也可以是本地ip.
    127.0.0.1 registry.com

###RUN
  - ./build 创建镜像
  - sudo fig up 没安装fig，自己搜索安装方法
  - sudo docker login https://registry.com
  - 用户名：evil
  - 密码:admin
  - 在上面脚本里可以改

###LINKS
  - [Protecting the Docker daemon Socket with HTTPS](https://docs.docker.com/articles/https/)
  - [nginx代理https](https://github.com/lightning-li/docker-nginx-auth-registry)
  - [搭建docker-registry时使用自签名ssl证书认证问题](https://www.webmaster.me/server/docker-registry-with-self-signed-ssl-certificate.html)
  - [搭建docker内网私服（docker-registry with nginx&ssl on centos）](http://segmentfault.com/blog/seanlook/1190000000801162)

