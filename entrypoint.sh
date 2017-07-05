#mysql has to be started this way as it doesn't work to call from /etc/init.d
service mysql start

# Here we generate random passwords (thank you pwgen!) for mysql users
MYSQL_PASSWORD=password

mysqladmin -u root password $MYSQL_PASSWORD
mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
killall mysqld

/usr/local/bin/supervisord -n -c /etc/supervisord.conf
