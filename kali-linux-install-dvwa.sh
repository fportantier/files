#!/bin/sh

echo "Installing packages..."

apt-get install -y apache2 curl libapache2-mod-php mariadb-server php-gd php-mysql wget

cd /var/www/html

rm -f index.html

echo "Downloading dvwa..."
rm -f master.zip
rm -rf DVWA-master

wget "https://github.com/ethicalhack3r/DVWA/archive/master.zip"

unzip -q master.zip

mv DVWA-master dvwa

echo "Changing permissions for dvwa directory..."
chown -R www-data:www-data dvwa

cd dvwa

echo "Copying dvwa config..."
cp config/config.inc.php.dist config/config.inc.php

echo "Configuring dvwa..."
sed -i s/\'root\'/\'dvwa\'/g config/config.inc.php

echo "Configuring PHP..."
PHPVER=$(ls -1 /etc/php | tail -1)
echo "allow_url_include = On" > /etc/php/$PHPVER/apache2/conf.d/99-dvwa.ini

echo "Configuring apache2..."
a2dismod mpm_event
a2enmod mpm_prefork
a2enmod php$PHPVER

echo "Enabling and starting apache2..."

systemctl enable apache2.service
systemctl restart apache2.service

echo "Enabling and starting mariadb..."

systemctl enable mariadb.service
systemctl restart mariadb.service

echo "Configuring mariadb..."

cat << EOF | mariadb
CREATE DATABASE IF NOT EXISTS dvwa;
GRANT ALL ON dvwa.* to dvwa@localhost IDENTIFIED BY 'p@ssw0rd';
FLUSH PRIVILEGES;
EOF

echo "Setting up dvwa database..."
curl 'http://127.0.0.1/dvwa/setup.php' -H 'Host: 127.0.0.1' --data 'create_db=Create+%2F+Reset+Database'

echo "Done. Opening dvwa in your browser..."

x-www-browser "http://127.0.0.1/dvwa"
