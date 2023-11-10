#!/bin/bash

#remember to run the script as sudo. Dangerous? Yes! Easier? Definitely!

#install nginx
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y

#install GIT & Hugo for intial deployment
sudo apt install git
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
    sudo certbot --nginx
    sudo ufw allow 443/tcp
else
    # The user did not press 1. Exit the script.
    echo "You did not press 1. Exiting the script."
    exit 1
fi
