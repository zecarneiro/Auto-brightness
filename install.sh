#!/bin/bash
# Autor: José M. C. Noronha
# Data: 20/05/2018

# Set Definition
nameApp="auto_brightness"
nameService="$nameApp.service"
nameExecutale="$nameApp.sh"
appFolder="AutoBrightness/"
pathApp="/opt/"
pathFileService="/lib/systemd/system/"
fileMinValueBattery="valueMin"

# Get info for min brightness
declare value
declare -i haveError=0
while [ 1 ]; do
	haveError=0
	read -p "Insert the value(in %) when battery is used( default is 30 ): " value

	# Verify if is integer
	if ! [[ $value =~ ^-?[0-9]+$ ]]; then
		echo "### Acept only integer ###"
		haveError=1
	else
		if [ $value -lt 0 ]||[ $value -gt 100 ]; then
			echo "### Acept only number betwen 0 and 100. value >= 0 and value <= 100 ###"
			haveError=1
		else
			declare -i countNotEqual=0
			for (( i = 0; i <= 100; i=i+10 )); do
				if [ $value -ne $i ]; then
					countNotEqual=countNotEqual+1
				fi
			done

			if [ $countNotEqual -eq 11 ]; then
				echo "### Acept only value multiple 0f 10: 0 10 20 30 ... ###"
				haveError=1
			fi
		fi
	fi

	if [ $haveError -eq 0 ]; then
		break
	fi
done

# Install
sudo cp -r $appFolder $pathApp
echo "$value" | sudo tee "$pathApp$appFolder$fileMinValueBattery" > /dev/null
sudo chmod -R 755 $pathApp$appFolder
sudo mv $pathApp$appFolder$nameService $pathFileService

# Enable Service
sudo systemctl daemon-reload
sudo systemctl enable $nameService
