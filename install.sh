#!/bin/bash
# My first script

sudo apt-get update 
sudo apt-get install python-pip python-dev libpq-dev postgresql postgresql-contrib nginx

export LC_ALL="en_US.UTF-8" 
export LC_CTYPE="en_US.UTF-8"

sudo -H pip install --upgrade pip
sudo -H pip install virtualenv

# Script to add a user to Linux system
if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p $pass $username
		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may add a user to the system"
	exit 2
fi

gpasswd -a lgili sudo
#su - lgili

cd home/lgili
git clone https://github.com/lgili/gili.io.git
mv gili.io django
cd django

virtualenv django_env
source django_env/bin/activate
pip install -r requirements.txt
python manage.py makemigrations
python manage.py migrate
python manage.py collectstatic 

sudo ufw allow 8000
python manage.py runserver 0.0.0.0:8000
echo "pronto!"
