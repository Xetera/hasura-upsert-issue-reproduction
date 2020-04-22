FROM postgres:12
COPY backup.sql /docker-entrypoint-initdb.d/init.sql
