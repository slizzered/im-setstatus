#!/bin/bash

# required stuff:
# - pidgin
# - python2
# - skype4py
# - notify-send
# - Dropbox

# Parameters for the user
DEBUG=1
WIRELESS_INTERFACE="wlan0"
U_HOME="/home/carli"
U_NAME="carli"
DEBUG_FILE="$U_HOME/pidgin_setstatus_debug.log"

# get your own api-key from google!
# https://developers.google.com/maps/documentation/business/geolocation/#api-key
API_KEY="$(cat apikey.dat)"

# internal variables
ESSID="ff/an"
MAC="00"
C=0;
while [ "$ESSID" = "ff/an" ] 
do
	IWC="$(/usr/sbin/iwconfig $WIRELESS_INTERFACE)"
	ESSID=$(echo "$IWC" | grep -o "ESSID:.*" | cut -c 8- | head -c -4)
	MAC=$(echo "$IWC" | grep -o "Access Point: .*" | cut -c 15-31 )

	if [ $C -ge 10 ]
	then 
		break 
	else
		C=$(( $C + 1 ))
		sleep 2s
	fi
done

LAT=0
LNG=0
ACCURACY=999999


############################# HELPER FUNCTIONS #########################################

# gets data from all the access-points around
apscan () {
	SCAN="$(/usr/sbin/iwlist $WIRELESS_INTERFACE scan)"
	ADDRESS=( $(echo "$SCAN" | grep -o "Address:.*" | cut -c 10-26) )
	STRENGTH=( $(echo "$SCAN" | grep -o "Signal level=.*" | cut -c 15-16) )
	CHANNEL=( $(echo "$SCAN" | grep -o "Channel .*)" | grep -o -e "[[:digit:]]\+") )
	SNR=( $(echo "$SCAN" | grep -o "Quality=[[:digit:]]\+" | cut -c 9-) )
	COUNT=$(echo "$SCAN" | grep -o "Address:.*" -c)
}

# uses the data from the Access Points to send them to google and get a fix on your location
google_location () {
	apscan
	if [ $COUNT -ge 2 ] ; then
		APLIST='['
		for (( i=0; i<$COUNT; i++ ))
		do
			# for each AP, build the appropriate string
			AP='{"macAddress": "'${ADDRESS[$i]}'","signalStrength": -'${STRENGTH[$i]}',"channel": '${CHANNEL[$i]}',"signalToNoiseRatio": '${SNR[$i]}'}'
			APLIST="$APLIST $AP,"
		done
		APLIST="$(echo "$APLIST" | head -c -2) ]"

	else # if there is only 1 AP, duplicate it to get the correct syntax (google wants at least 2 APs, so we shouldn't do this...)
		APLIST='['
		for i in 0 0
		do
			AP='{"macAddress": "'${ADDRESS[$i]}'","signalStrength": -'${STRENGTH[$i]}',"channel": '${CHANNEL[$i]}',"signalToNoiseRatio": '${SNR[$i]}'}'
			APLIST="$APLIST $AP,"
		done
		APLIST="$(echo "$APLIST" | head -c -2) ]"

	fi

	# query google with our string and parse the relevant data
	REPL=$(/usr/bin/curl -s -d '{"wifiAccessPoints": '"$APLIST"'}' -H "Content-Type: application/json" -i "https://www.googleapis.com/geolocation/v1/geolocate?key=$API_KEY")
	echo "$REQ"
	
	if [ "$(echo "$REPL" | grep -e 'HTTP.*200 OK' -c )" = "1" ] ; then
		LAT="$(echo "$REPL" | grep -o '"lat": .*' | cut -c 8-16)"
		LNG="$(echo "$REPL" | grep -o '"lng": .*' | cut -c 8-16)"
		ACCURACY="$(echo "$REPL" | grep -o -e '"accuracy": [[:digit:]]\+' | grep -o -e '[[:digit:]]\+')"
	fi
}


#################### Main Program starts here #############################

# if we are not root, there will only be 1 access point, which is usually not sufficient for our purposes
if [ "`/usr/bin/whoami`" != "root" ] ; then
	echo "ATTENTION. This should be run as root, to receive all necessary values!"
fi

if [ "$1" = "--backoff" ] ; then
	sleep $2
fi

# clear the debug log
if [ $DEBUG -ge 1 ] ; then echo "" > $DEBUG_FILE ; fi

# write first part of the message based on known (manually entered) information.
case "$ESSID" in
	"SCinfrastructure")				MESSAGE="@Dresden" ;;
	"THE_INTERNET")					MESSAGE="@Casa de Philipp" ;;
	"WLAN700")						MESSAGE="@Hof/Hotel" ;;
	"WUNDERLAND")					MESSAGE="@Casa de Hamster";;
	"HZDR")							MESSAGE="@HZDR";;
	"eduroam")
		case "$MAC" in
			#"C4:7D:4F:57:91:61")	MESSAGE="@SLUB";;
			#"C4:7D:4F:51:69:B1")	MESSAGE="@SLUB";;
			#"C4:7D:4F:52:5F:11")	MESSAGE="@SLUB";;
			#"C4:7D:4F:51:DF:D1")	MESSAGE="@SLUB";;
			"C4:7D:4F:"*)			MESSAGE="@SLUB";;
			"00:11:88:"*)			MESSAGE="@HZDR" ;;
			"08:17:35:33:5A:11")	MESSAGE="@INF/E051" ;;
			"08:17:35:82:B0:A1")	MESSAGE="@INF/E046" ;;
			"08:17:35:83:1F:B1")    MESSAGE="@ascii" ;;
			"08:17:35:9D:38:71")	MESSAGE="@ascii" ;;
			"08:17:35:"*)			MESSAGE="@INF" ;;
			*)						MESSAGE="eduroam";;
		esac ;;
	*)	
		case "$MAC" in
			"00:1C:4A:D0:03:FD")	MESSAGE="@Oberkotzau";;
			*)						MESSAGE="@unknown location"	;;
		esac ;;
esac

# try to get more information using google
google_location

# only use coordinates, if we are accurate enough
if [ $ACCURACY -le 250 ] ; then 
	#rev_geocoding:
	MESSAGE="$MESSAGE ("

	GEO=$(curl -s -i "http://maps.googleapis.com/maps/api/geocode/json?latlng=$LAT,$LNG&sensor=false")
	if [ $(echo $GEO | grep -c -e "\"status\" : \"OK\"") -eq 1 ] ; then
		#GEO_ROUTE="$(echo $GEO | tr '\n' ' ' | grep -o -P -e "formatted_address.*?route")"
		GEO_ADDR="$(echo $GEO | grep -o -P -e "formatted_address\"\ :\ \".*?\"" | head -1)"
		GEO_ADDR="$(echo $GEO_ADDR | tail -c +23 | head -c -2)"
		GEO_ADDR="$(echo $GEO_ADDR | tr 'ß' 'ss' | tr 'ö' 'oe' | tr 'ü' 'ue' | tr 'ä' 'ae')"
		MESSAGE="${MESSAGE}${GEO_ADDR}"
	fi
		MESSAGE="$MESSAGE https://maps.google.de/?q=$LAT,$LNG )"
else
	MESSAGE="$MESSAGE (using $ESSID)"
fi

# log some information into Dropbox (in case laptop gets stolen)
sudo -u $U_NAME mkdir $U_HOME/Dropbox/Location/ 2>/dev/null
sudo -u $U_NAME echo "$LAT,$LNG,$ESSID,$MAC" | sudo -u $U_NAME tee -a "$U_HOME/Dropbox/Location/$(date +%F\ %T).txt"

#Notify the user, what's going on
DISPLAY=:0 sudo -u $U_NAME purple-remote "setstatus?message=$MESSAGE"

# update your Pidgin-Status
DISPLAY=:0 sudo -u $U_NAME notify-send -u low -t 3000 "Pidgin-Status" "$MESSAGE"

# update your Skype-Status
if [ $(ps -aux | grep Skype | wc -l) -gt 1 ] ; then
DISPLAY=:0 sudo -u $U_NAME /usr/bin/python2 << END
import Skype4Py
skype = Skype4Py.Skype()
skype.FriendlyName = 'location_query_service'
skype.Attach()
skype.CurrentUserProfile.MoodText = '$MESSAGE'
END
fi

# leave some debug information behind
if [ $DEBUG -ge 1 ] ; then
	echo -e "IWC: $IWC\n\n" >> $DEBUG_FILE
	echo -e "SCAN:$SCAN\n\n" >> $DEBUG_FILE
	echo -e "REPL:\n$REPL\n\n" >> $DEBUG_FILE
	echo -e "APLIST:\n$APLIST\n\n" >> $DEBUG_FILE
	echo "ESSID: $ESSID" >> $DEBUG_FILE
	echo "MAC: $MAC" >>   $DEBUG_FILE
	echo "ADDRESS: ${ADDRESS[@]}" >> $DEBUG_FILE
	echo "STRENGTH: ${STRENGTH[@]}" >> $DEBUG_FILE
	echo "CHANNEL: ${CHANNEL[@]}" >> $DEBUG_FILE
	echo "SNR: ${SNR[@]}" >> $DEBUG_FILE
	echo "COUNT: $COUNT" >> $DEBUG_FILE
fi
exit 0
