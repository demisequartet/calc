FROM mysql:5.6

ENV MYSQL_ROOT_PASSWORD=password

COPY my.cnf /etc/mysql/conf.d/my.cnf
RUN cd /etc/mysql/conf.d/ && chmod 644 my.cnf

