FROM workshop-remote-host

RUN yum -y install nginx

EXPOSE 80 443

VOLUME /var/www/html /var/log/nginx

COPY ./conf/nginx.conf /etc/nginx/conf.d/default.conf

COPY ./bin/start.sh /start.sh

RUN chmod +x /start.sh

CMD /start.sh
