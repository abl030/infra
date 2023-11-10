#!/bin/bash

# This script is designed to run on the host.

#double check things are installed
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

# Reload the nginx config
sudo nginx -t && systemctl reload nginx

#cleanup
sudo rm -rf ./AndyBlog

# Delete the script in all cases.
rm -- "$0"