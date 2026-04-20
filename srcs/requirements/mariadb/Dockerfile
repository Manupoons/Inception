FROM alpine:3.21

RUN apk update
RUN apk add mariadb mariadb-client

COPY ./tools/mariadb.sh /tmp/mariadb.sh
RUN chmod +x /tmp/mariadb.sh
ENTRYPOINT ["ash", "/tmp/mariadb.sh"]

EXPOSE 3306

CMD ["mariadbd-safe"]