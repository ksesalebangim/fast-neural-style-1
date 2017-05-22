#!/bin/bash
aseqdump -p "LPD8" | \
while IFS=" ," read src ev1 ev2 ch label1 data1 label2 data2 rest; do
    case "$ev1 $ev2 $data1" in
        "Note on 36" ) xdotool type hello ;;
        "Note on 38" ) xdotool key ctrl+j ;;
    esac
done
