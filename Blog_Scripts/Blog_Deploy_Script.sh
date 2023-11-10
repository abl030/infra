#!/bin/bash

# This script is designed to run on the host.

#double check things are installed
sudo apt install git
sudo snap install hugo

#clone the repo and deploy
git clone --recurse-submodules https://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@github.com/abl030/AndyBlog.git
#chown -R abl030 ./AndyBlog 
hugo -s ./AndyBlog
sudo cp -r ./AndyBlog/public /home/${SITE_USER}/

#cleanup
sudo rm -rf ./AndyBlog