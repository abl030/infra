#!/bin/bash

#remember to run the script as sudo. Dangerous? Yes! Easier? Definitely!

#install nginx
apt update
apt install nginx certbot python3-certbot-nginx -y

#define our variables
SITE_USER=www-blog-barrett
SITE_URL=blog.barrett-lennard.com

#add a user for our blog
adduser $SITE_USER --disabled-password --gecos ""

#make a public directory for the above user
mkdir /home/$SITE_USER/public
chown $SITE_USER /home/$SITE_USER/public

## make the default http nginx config to allow acme protocul
echo "server {
    listen 80;
    listen [::]:80;
    server_name ${SITE_URL} www.${SITE_URL};

    root        /home/${SITE_USER}/public;
    charset     utf-8;

    location / {
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name ${SITE_URL};

    return      301 http://${SITE_URL}$request_uri;
}" > /etc/nginx/sites-available/$SITE_USER

# Enable the site config
ln -s /etc/nginx/sites-available/$SITE_USER /etc/nginx/sites-enabled/$SITE_USER

# Reload the nginx config
nginx -t && systemctl reload nginx

#Enable port 80 ufw
ufw enable
ufw allow 80

# Print the current local IP address (for the default network interface)
echo "Your current local IP address is:"
ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1

# Inform the user to forward port 80 to the correct IP
echo "Please ensure that port 80 is forwarded to the above IP address in your router settings."

# Wait for the user to press 1
read -p "After forwarding port 80, press 1 to continue: " userInput

if [ "$userInput" = '1' ]; then
    # Enable HTTPS
    certbot --nginx
    ufw allow 443/tcp
else
    # The user did not press 1. Exit the script.
    echo "You did not press 1. Exiting the script."
    exit 1
fi
