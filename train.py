#please note that the h5 file needs to be in this folder under the name trainer.h5

import os
from os import listdir
from os.path import isfile, join
import subprocess
import sys
import time
import shlex, subprocess
def ensure_dir(file_path):
    directory = os.path.dirname(file_path)
    if not os.path.exists(directory):
        os.makedirs(directory)
def main(d):
	#d="/home/midburn/Dropbox/midburn"
	inputd = d+"/input_images"
	directoriez = [os.path.join(inputd,o) for o in os.listdir(inputd) if os.path.isdir(os.path.join(inputd,o))]
	for direc in directoriez:
		onlysubdir=direc.split("/")[-1]
		if len(onlysubdir.split("_"))==3:
			onlyfiles = [f for f in listdir(direc) if isfile(join(direc, f))]
			for myfile in onlyfiles:
				if myfile[-4:].lower()==".jpg":
					os.rename(inputd+"/"+onlysubdir+"/"+myfile, inputd+"/"+onlysubdir+"/"+myfile+".trained")
					arguments=onlysubdir.split("_")
					mdirname=os.path.dirname(os.path.realpath(__file__))
					ensure_dir(mdirname+"/mymodels/"+onlysubdir+"/")
					
					
					command= "th train.lua -h5_file trainer.h5 -style_image "+inputd+"/"+onlysubdir+"/"+myfile+".trained"+" -style_image_size 512 -content_weights "+arguments[0]+" -style_weights "+arguments[1]+" -batch_size 1 -num_iterations "+arguments[2]+" -checkpoint_name mymodels/"+onlysubdir+"/"+myfile[:-4]+" -gpu 0"
					print command
					command= shlex.split(command)
					sub_process = subprocess.Popen(command, stdout=subprocess.PIPE)
					while sub_process.poll() is None:
					    out = sub_process.stdout.read(1)
					    sys.stdout.write(out)
					    sys.stdout.flush()
					
					outd = d+"/output_images/"+onlysubdir
					ensure_dir(outd+"/")
					command ="th fast_neural_style.lua -model "+"mymodels/"+onlysubdir+"/"+myfile[:-4]+".t7"+" -input_image baseline.jpg -output_image "+outd+"/"+myfile+" -gpu 0"
					print command
					command=command.split(" ")
					sub_process = subprocess.Popen(command, stdout=subprocess.PIPE)
					while sub_process.poll() is None:
					    out = sub_process.stdout.read(1)
					    sys.stdout.write(out)
					    sys.stdout.flush()
					os.rename(inputd+"/"+onlysubdir+"/"+myfile+".trained",inputd+"/"+onlysubdir+"/"+myfile+".complete")
					print("trained "+"train_script/"+onlysubdir+"/"+myfile)
					return
if len(sys.argv)<2:
	print("please insert midburn folder dropbox path (no spaces!)\npython train.py /path/to/midburn")
	exit(0)
else:
	tpath = sys.argv[1]
	while True:
		main(tpath)
		time.sleep(10)