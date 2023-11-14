#!/bin/bash

#remember to run the script as sudo. Dangerous? Yes! Easier? Definitely!

#stop execution if command fails
set -e

#install nginx
sudo apt update

#Originally just had the ubuntu package, but its waaaaay out of date. So using the NGINX package manager.
#at time of writing ubuntu package was 1.18.0 and the nginx current was: 1.24.0

# Install prerequisites
sudo apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring -y

#need to intialise the gpg directory and keyring files, otherwise it errors out.
gpg --list-keys

# Set up the apt repository for nginx packages
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list

# Set up repository pinning
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99nginx

# Install nginx
sudo apt update
sudo apt install nginx -y


#install GIT & Hugo for intial deployment
sudo apt install git -y
sudo snap install hugo

#define our variables
SITE_USER=www-data
SITE_URL=blog.barrett-lennard.com

#clone the repo and deploy
git clone --recurse-submodules https://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@github.com/abl030/AndyBlog.git
#chown -R abl030 ./AndyBlog 
hugo -s ./AndyBlog
sudo cp -r ./AndyBlog/public /home/${SITE_USER}/

#cleanup
sudo rm -rf ./AndyBlog

#add a user for our blog
sudo adduser $SITE_USER --disabled-password --gecos ""

#make a public directory for the above user
sudo mkdir /home/$SITE_USER/public
sudo chown -R $SITE_USER /home/$SITE_USER/public
sudo chgrp -R $SITE_USER /home/$SITE_USER/public

## make the default http nginx config to allow acme protocul
sudo tee /etc/nginx/sites-available/$SITE_USER > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${SITE_URL} www.${SITE_URL};

    root        /home/${SITE_USER}/public;
    charset     utf-8;

    location / {
    }
}
EOF


# Enable the site config
sudo ln -s /etc/nginx/sites-available/$SITE_USER /etc/nginx/sites-enabled/$SITE_USER

# Reload the nginx config
sudo nginx -t && systemctl reload nginx

#Enable port 80 ufw
sudo ufw enable
sudo ufw allow 80

# Print the current local IP address (for the default network interface)
echo "Your current local IP address is:"
ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1

# Inform the user to forward port 80 to the correct IP
echo "Please ensure that port 80 is forwarded to the above IP address in your router settings."

# Wait for the user to press 1
read -p "After forwarding port 80, press 1 to continue: " userInput

if [ "$userInput" = '1' ]; then
    # Enable HTTPS
    sudo certbot --nginx --non-interactive --agree-tos --email abl030@gmail.com --expand -d blog.barrett-lennard.com,www.blog.barrett-lennard.com
    sudo ufw allow 443/tcp
else
    # The user did not press 1. Exit the script.
    echo "You did not press 1. Exiting the script."
    rm -- "$0"
    exit 1
fi

# Delete the script in all cases.
rm -- "$0"
