#!/bin/bash

last_reality=0
last_effect=0

function reality {
	if [ $last_reality -gt $1 ]
	then
		xdotool key Up
	else
		xdotool key Down
	fi
	last_reality=$1
}

function effect {
	if [ $last_effect -gt $1 ]
	then
		xdotool key Right
	else
		xdotool key Left
	fi
	last_effect=$1
}

echo 'Started. on errors - plug and unplug the midi controller'
aseqdump -p "LPD8" | \
while IFS=" ," read src ev1 ev2 ch label1 data1 label2 data2 rest; do
    case "$ev1 $ev2 $ch $data1" in
        "Note on 0 40" ) xdotool type n ;;
        "Control change 0 5" ) xdotool type n;;
        "Program change 0 4" ) xdotool type n;;

        "Note on 0 36" ) xdotool type p ;;
        "Control change 0 1" ) xdotool type p;;
        "Program change 0 0" ) xdotool type p;;

        "Note on 0 41" ) xdotool type ' ' ;;
        "Control change 0 6" ) xdotool type ' ' ;;
        "Program change 0 5" ) xdotool type ' ' ;;

        "Note on 0 43" ) xdotool type s ;;
        "Control change 0 9" ) xdotool type s ;;
        "Program change 0 7" ) xdotool type s ;;

        "Control change 0 8" ) reality $data2 ;;
        "Control change 0 7" ) effect $data2 ;;
    esac
    if [ "$ev2" == "unsubscribed" ]
    then
      echo 'Disconnected. Restarting'
      $0 "$@" &
      exit 0 
    fi
done
echo "Closing... sleepin 10 seconds in case midi was disconnected"
sleep 10
echo "Exit read midi"
