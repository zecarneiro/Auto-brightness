#!/bin/bash
# Autor: José M. C. Noronha
# Data: 20/05/2018

# Settings
nameApp="auto_brightness"
nameService="$nameApp.service"
nameExecutale="$nameApp.sh"
nameServiceControl="$nameAppServiceControl.sh"
locationPIDFile="/tmp/$nameApp.pid"
messageStart="$nameApp: Starting $nameApp service"
messageStop="$nameApp: Stopping $nameApp service"
locationApp="/opt/AutoBrightness/"

# Start Service
function service_start(){
	echo $messageStart
	ps aux | grep "$nameServiceControl start" | grep -v grep | awk '{print $2}' > $locationPIDFile
	bash $locationApp$nameExecutale
	sleep 5
	echo "PID is $(cat $locationPIDFile)"
}

# Stop Service
function service_stop(){
	echo $messageStop
	kill $(cat $locationPIDFile)
	rm $locationPIDFile
}

# Status Service
function service_status(){
	ps aux | grep "$nameServiceControl start" | grep -v grep 
}

# Main
case "$1" in
	start)
		service_start
		;;
	stop)
		service_stop
		;;
	status)
		service_status
		;;
	*)
		echo "Usage: $0 {start | stop | reload | status}" 
		exit 1
	;;
esac

exit 0