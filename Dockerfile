FROM daocloud.io/library/node:8.11.1-slim

MAINTAINER congyuandong <congyuandong@gmail.com>

RUN npm install -g cnpm --registry=https://registry.npm.taobao.org

WORKDIR /app

COPY . /app/

RUN npm install -g hexo-cli && \
  cnpm install --production && \
  hexo g

VOLUME /var/www/blog:/app/public