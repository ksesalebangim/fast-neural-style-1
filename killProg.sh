#!/bin/sh
sudo supervisorctl stop pyserver
sudo supervisorctl stop webcamdemo
sudo killall qlua
sudo killall python
sudo killall sudo
#visudo
#username COMOUTERNAME= NOPASSWD: /path/to/your/script
#add shortcut from ubuntu keyboard settings
