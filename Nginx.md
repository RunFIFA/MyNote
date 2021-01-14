Nginx：

Docker-compose:
version: '3.1'
services:
  nginx:
    container_name: nginx
    image: daocloud.io/library/nginx
    restart: always
    ports:
      -80:80
    volumes:
      -./conf.d/:/etc/nginx/conf.d

-----



配置文件：/etc/nginx/nginx.conf    /etc/nginx/conf.d/default.conf

upstream my-server{
	hash_ip;
	server techad.top:8080 weight=5;
	server techad.top:8081 weight=2;
}
server{
	listen 80;
	server_name localhost;
	location =/index {	# 动态页面
		proxy_pass http://my-server/;
	}
	location /html {	# 静态资源配置
		root /data
		index index.html index.htm
		autoindex on;
	}
}