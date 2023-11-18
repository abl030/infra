#!/bin/bash

#remember to run the script as sudo. Dangerous? Yes! Easier? Definitely!

## Originally used the Ubuntu PPA but it's out of date.
## as of writing its at 1.18 and the nginx repo is 1.24.
## installing the NGINX repo caused issues in testing, hence the code became complicated.

set -x

sudo apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring -y

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list

echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | sudo tee /etc/apt/preferences.d/99nginx

sudo apt update
sudo apt install nginx -y

#install certbot
sudo apt install certbot python3-certbot-nginx git -y

#install Hugo for intial deployment
sudo snap install hugo

# Prompt user for the SITE_PREFIX
read -p "Enter the site prefix: " SITE_PREFIX

# Prompt the user for the SITE_DOMAIN
read -p "Enter the site domain: " SITE_DOMAIN

#Prompt user for Email
read -p "Enter your email address for CertBot: " EMAIL

# Prompt user for GitHub access token
read -p "Enter your GitHub access token: " GITHUB_TOKEN

# Set the user variable
SITE_USER="www-data"

#download all the scripts and service files
git clone https://github.com/abl030/infra.git

# Clone the repo and deploy
git clone --recurse-submodules "https://${GITHUB_TOKEN}@github.com/abl030/AndyBlog.git"

#Hugo Create and move into the prod public directory
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

#add our nginx user for the service
sudo useradd -m -d /home/nginx -g nginx -s /bin/bash nginx

## copy our two nginx conf files
sudo cp ./infra/Blog_Deploy/nginx.conf /etc/nginx/nginx.conf
sudo cp ./infra/Blog_Deploy/blog.barrett-lennard.conf /etc/nginx/conf.d/blog.barrett-lennard.conf
sudo sed -i "s/site_prefix/$SITE_PREFIX/g; s/site_domain/$SITE_DOMAIN/g" /etc/nginx/conf.d/blog.barrett-lennard.conf


## copy our nginx service file
sudo cp ./infra/Blog_Deploy/nginx.service /usr/lib/systemd/system/nginx.service

## copy our certbot domain hook script
sudo cp ./infra/Blog_Deploy/deploy_certs.sh /etc/letsencrypt/renewal-hooks/deploy/deploy_certs.sh
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/deploy_certs.sh
sudo sed -i "s/site_prefix/$SITE_PREFIX/g; s/site_domain/$SITE_DOMAIN/g" /etc/letsencrypt/renewal-hooks/deploy/deploy_certs.sh

##reload systemctl daemon
sudo systemctl daemon-reload

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
    sudo certbot certonly --webroot -w /home/www-data/public --staple-ocsp --non-interactive --agree-tos --email $EMAIL --expand -d "${SITE_URL.SITE_DOMAIN},www.${SITE_URL.SITE_DOMAIN}"
    sudo ufw allow 443/tcp
else
    # The user did not press 1. Exit the script.
    echo "You did not press 1. Exiting the script."
    rm -- "$0"
    exit 1
fi

#execute our cert script to ensure certs are in the right spot
sudo ./etc/letsencrypt/renewal-hooks/deploy/deploy_certs.sh

# Start Nginx service
sudo systemctl start nginx

# Reload the nginx config
sudo nginx -t && systemctl reload nginx

# Delete the script in all cases.
rm -- "$0"
