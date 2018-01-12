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

gpasswd -a $username sudo
#su - lgili

cd home/$username
git clone https://github.com/lgili/gili.io.git
mv gili.io django
cd django

virtualenv django_env
source django_env/bin/activate
pip install -r requirements.txt
python manage.py makemigrations
python manage.py migrate
python manage.py collectstatic 

#sudo ufw allow 8000
#python manage.py runserver 0.0.0.0:8000
deactivate

cat <<EOF > /etc/systemd/system/gunicorn.service
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=$username
Group=www-data
WorkingDirectory=/home/$username/django
ExecStart=/home/$username/django/django_env/bin/gunicorn --access-logfile - --workers 3 --bind unix:/home/$username/django/django_project.sock django_project.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl daemon-reload
sudo systemctl restart gunicorn


cat <<EOF > /etc/nginx/sites-available/django_project
server {
    listen 80;
    server_name 104.131.59.213 gili.io www.gili.io;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /home/$username/django;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/$username/django/django_project.sock;
    }
}

EOF


sudo ln -s /etc/nginx/sites-available/django_project /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx
sudo ufw allow 'Nginx Full'

echo "pronto!"
