#!/bin/bash
#update the VM's package repository
sudo apt update -y
#install apache webserver
sudo apt install apache2 -y
#add the php ondrej repository
sudo add-apt-repository ppa:ondrej/php --yes
#update the VM's package repository again
sudo apt update -y
# install php8.2
sudo apt install php8.2 -y
#install missing php dependencies needed for laravel
sudo apt install php8.2-curl php8.2-dom php8.2-mbstring php8.2-xml php8.2-mysql zip unzip -y
#enable rewrite
sudo a2enmod rewrite
#restart apache server
sudo systemctl restart apache2
#change directory to the /usr/bin directory and install composer
cd /usr/bin
install composer globally -y
sudo curl -sS https://getcomposer.org/installer | sudo php -q
#rename composer.phar to composer
sudo mv composer.phar composer
#change directory to the /var/www directory to clone laravel repo into a new laravel folder
cd /var/www/
sudo git clone https://github.com/laravel/laravel.git
sudo chown -R $USER:$USER /var/www/laravel
cd laravel/
install composer autoloader
composer install --optimize-autoloader --no-dev --no-interaction
composer update --no-interaction
#copy the content of the default env file to a new .env file
sudo cp .env.example .env
#change ownership of the storage and bootstrap/cache files to www-data, which is the user our Apache webserver runs as
sudo chown -R www-data storage
sudo chown -R www-data bootstrap/cache
cd
#change directory into the apache sites available folder to create a new config file for the laravel application
cd /etc/apache2/sites-available/
sudo touch latest.conf
sudo echo '<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/laravel/public

    <Directory /var/www/laravel>
        AllowOverride All
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/laravel-error.log
    CustomLog ${APACHE_LOG_DIR}/laravel-access.log combined
</VirtualHost>' | sudo tee /etc/apache2/sites-available/latest.conf
#disable the apache default site and enable the laravel application site
sudo a2ensite latest.conf
sudo a2dissite 000-default.conf
#restart the apache service to apply the changes
sudo systemctl restart apache2
#install mysql and setup database
cd
sudo apt install mysql-server -y
sudo apt install mysql-client -y
sudo systemctl start mysql
sudo mysql -uroot -e "CREATE DATABASE Friends;"
sudo mysql -uroot -e "CREATE USER 'olu'@'localhost' IDENTIFIED BY 'olu';"
sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON Friends.* TO 'olu'@'localhost';"
cd /var/www/laravel
sudo sed -i "23 s/^#//g" /var/www/laravel/.env
sudo sed -i "24 s/^#//g" /var/www/laravel/.env
sudo sed -i "25 s/^#//g" /var/www/laravel/.env
sudo sed -i "26 s/^#//g" /var/www/laravel/.env
sudo sed -i "27 s/^#//g" /var/www/laravel/.env
sudo sed -i '22 s/=sqlite/=mysql/' /var/www/laravel/.env
sudo sed -i '23 s/=127.0.0.1/=localhost/' /var/www/laravel/.env
sudo sed -i '24 s/=3306/=3306/' /var/www/laravel/.env
sudo sed -i '25 s/=laravel/=Friends/' /var/www/laravel/.env
sudo sed -i '26 s/=root/=olu/' /var/www/laravel/.env
sudo sed -i '27 s/=/=olu/' /var/www/laravel/.env
sudo php artisan key:generate
sudo php artisan storage:link
sudo php artisan migrate
sudo php artisan db:seed
sudo systemctl restart apache2
