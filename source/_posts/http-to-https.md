---
title: HTTP to HTTPS
tags:
  - https
  - let's encrypt
  - assistant
  - slack
---

Home Assistant、天猫精灵、slack等等服务都需要使用`https`协议

## let's encrypt

> Let’s Encrypt is a free, automated, and open Certificate Authority.

主要是免费，而且目前已经支持通配符，虽然只有90天的时长，但是可以自动续期，so，[let's encrypt](https://letsencrypt.org/getting-started/)

### With Shell Access

因为是自有云主机，所以直接选择`shell`模式，使用[Certbot](https://certbot.eff.org/)来安装，在主页选择自己的`web`容器和系统版本

### Nginx on CentOS/RHEL 7

```
wget https://dl.eff.org/certbot-auto
chmod a+x ./certbot-auto
```
<!-- more -->
### wildcard certificate

执行以下命令申请证书，别忘了加上主域名

```
sudo ./certbot-auto --server https://acme-v02.api.letsencrypt.org/directory -d "*.congyuandong.cn" -d "congyuandong.cn" --manual --preferred-challenges dns-01 certonly
```

因为采用`dns-01`来校验所有权，会有以下提示，所以需要域名服务商处增加DNS解析，如果启动了主域名，以下步骤需要进行两次

```
Please deploy a DNS TXT record under the name
_acme-challenge.congyuandong.cn with the following value:

24FlhrIrgMlpBNLc2rLPKndaxvdCAWNLAQsSBOkLYAc

Before continuing, verify the record is deployed.
```

![](http://p8uxj765t.bkt.clouddn.com/15264471281902.jpg)

增加好了之后使用以下命令进行确认，然后再继续操作

```
dig _acme-challenge.congyuandong.cn txt
```

其他的校验形式：

* dns-01：给域名添加一个 DNS TXT 记录。
* http-01：在域名对应的 Web 服务器下放置一个 HTTP well-known URL 资源文件。
* tls-sni-01：在域名对应的 Web 服务器下放置一个 HTTPS well-known URL 资源文件。

不出意外的话即可申请成功

![](http://p8uxj765t.bkt.clouddn.com/15264475937788.jpg)

## nginx configuration
### https

```
server {
    server_name www.congyuandong.cn alias congyuandong.cn;
    listen 443 ssl;
    ssl on;
    ssl_certificate /etc/letsencrypt/live/congyuandong.cn/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/congyuandong.cn/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/congyuandong.cn/chain.pem;

    location / {
        root /usr/share/nginx/html/blog/;
        index index.html;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### rewrite http to https

```
server {
    listen 80;
    server_name www.congyuandong.cn alias congyuandong.cn;

    return 301 https://$server_name$request_uri;

    location / {
        root /usr/share/nginx/html/blog/;
        index index.html;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Auto renew

每次申请的证书都只有90天有效期，作为健忘症患者当然希望可以自动进行更新，最方便的方法是使用`cron job`

![](http://p8uxj765t.bkt.clouddn.com/15265332899858.jpg)

根据官方的建议一天更新两次:

> if you're setting up a cron or systemd job, we recommend running it twice per day (it won't do anything until your certificates are due for renewal or revoked, but running it regularly would give your site a chance of staying online in case a Let's Encrypt-initiated revocation happened for some reason). Please select a random minute within the hour for your renewal tasks.

`crontab -e`进入任务编辑页面，输入以下脚本：

``` shell
0 0,12 * * * python -c 'import random; import time; time.sleep(random.random() * 3600)' && /root/certbot-auto renew 
```

然后重启服务

```
systemctl restart crond.service
```




