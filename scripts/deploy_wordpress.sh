#!/bin/bash
set -ex

#Importamos el archivo .env
source .env

#Eliminamos descargas previas de latest.zip
rm -rf /tmp/latest.zip*

#Descargamos la ultima version de wordpress
wget https://wordpress.org/latest.zip -P /tmp

#Actualizamos los repositiorios de paquetes
apt update

#INstalamos unzip si no esta instalado
apt install unzip -y

#Eliminamos instalaciones previas de wordpress si existen
rm -rf /var/www/html/*
rm -rf /tmp/wordpress

#Descomprimimos el archivo descargado en /var/www/html
unzip /tmp/latest.zip -d /tmp/

#Movemos los archivos de wordpress a la raiz del directorio web
mv /tmp/wordpress/* /var/www/html/

#Creamos la base de datos y el usuario para wordpress
mysql -u root -e "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root -e "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root -e "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root -e "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root -e "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"


#Configuramos el archivo wp-config.php
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

#Reemplazamos los valores del usuario de la base de datos en el archivo wp-config.php
sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wp-config.php

#Modificamos los permisos de los archivos y directorios de wordpress
chown -R www-data:www-data /var/www/html/

#Copiamos el archivo .htaccess a la raiz del directorio web
cp ../.htaccess/.htaccess /var/www/html/.htaccess

#Habilitamos el módulo rewrite de apache
a2enmod rewrite

#Reiniciamos el servicio de apache para que tome los cambios
systemctl restart apache2