FROM alpine:3.22

RUN apk update
RUN apk add mariadb-client \
			openssl \
			curl \
			php83 \
			php83-fpm \
			php83-mysqli \
			php83-curl \
			php83-zip \
			php83-mbstring \
			php83-phar

COPY ./tools/wordpress.sh /tmp/wordpress.sh
RUN chmod +x /tmp/wordpress.sh

ENTRYPOINT ["ash", "/tmp/wordpress.sh"]

EXPOSE 9000

CMD ["php-fpm83", "-F"]