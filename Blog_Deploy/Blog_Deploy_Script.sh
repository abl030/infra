#!/bin/bash

# This script is designed to run on the host.

#double check things are installed
sudo apt install git
sudo snap install hugo

#define our variables
SITE_USER=www-data

# Prompt user for GitHub access token
read -p "Enter your GitHub access token: " GITHUB_TOKEN

# Clone the repo and deploy
git clone --recurse-submodules "https://${GITHUB_TOKEN}@github.com/abl030/AndyBlog.git"

#Hugo Create
hugo -s ./AndyBlog

#Remove old /public and move it then new
sudo rm -rf /home/${SITE_USER}/public
sudo cp -r ./AndyBlog/public /home/${SITE_USER}/

# Reload the nginx config
sudo nginx -t && systemctl reload nginx

#cleanup
sudo rm -rf ./AndyBlog

#As we've moved out the access token, we no loger need to delete the script.
# Delete the script in all cases.
#rm -- "$0"