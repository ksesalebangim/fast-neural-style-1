#!/bin/sh

python /home/midburn/python_server/httpServer.py&
cd /media/midburn/fast-neural-style-1
qlua /media/midburn/fast-neural-style-1/main.lua -gpu 0 -sequence psy
./media/midburn/fast-neural-style-1/read_midi.sh
sleep 10
