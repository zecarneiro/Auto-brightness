#!/bin/sh
# Autor: José M. C. Noronha
# Data: 20/05/2018

# Set Definition
nameApp="auto_brightness"
nameService="$nameApp.service"
appFolder="AutoBrightness/"
pathApp="/opt/"
pathFileService="/lib/systemd/system/"

# Stop and disable Service
sudo systemctl stop $nameService
sudo systemctl disable $nameService
sudo systemctl daemon-reload

# Uninstall
sudo rm -r $pathApp$appFolder
sudo rm $pathFileService$nameService