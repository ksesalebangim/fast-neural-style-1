#!flask/bin/python
from flask import Flask
import sound2
#from bleBulb import *
from led2 import *
import re
import pyscreenshot as ImageGrab
import time
import os
import threading
import subprocess
global basePath
basePath = os.path.dirname(os.path.realpath(__file__))
basePath = basePath+"/"
from flask import request
global mixer
mixer = sound2.myMixer(basePath+"sounds/")
#global bulb
#bulb=bleBulb("74:DA:EA:91:0B:84")
global strip
#strip = myled()

global mytimer
mytimer = int(time.time())
global threadEvent
threadEvent = threading.Event()
threadEvent.clear()



def shutdown_server():
    try:
        func = request.environ.get('werkzeug.server.shutdown')
        if func is None:
            raise RuntimeError('Not running with the Werkzeug Server')
        func()
    except Exception as e:
        pass
shutdown_server()
time.sleep(2)
app = Flask(__name__)
def watchdogLoop():
    while threadEvent.is_set():
        if mytimer + 3 < int(time.time()):
            p = subprocess.Popen(['killall','qlua'], stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
            out, err = p.communicate()
            threadEvent.clear()

@app.route('/')
def index():
    return "Hello, World!"

@app.route('/led/<led>')
def led(led):
    led = re.sub(",$","",led)
    led = str(led).replace(",,",",")

    if len(led.split(",")) % 4 ==0:
        strip.setColors(led)
    return led

@app.route('/screenshot')
def screenshot():
    ImageGrab.grab_to_file(basePath+"images/"+str(int(time.time()))+".jpg")
    mixer.play(str("camera.ogg"), 0)
    return ""

@app.route('/playSound/<string:fileName>/fadeIn/<int:fadeInMS>')
def playSound(fileName,fadeInMS):
    mixer.play(str(fileName),fadeInMS)
    return fileName

@app.route('/stopSound/<string:fileName>')
def stopSound(fileName):
    mixer.stop(str(fileName))
    return fileName

@app.route('/stopAllSounds')
def stopAllSounds():
    mixer.stopAll()
    return "All sounds stopped"

@app.route('/fadeOut/<string:fileName>/fadeOut/<int:fadeOutMS>')
def fadeOut(fileName,fadeOutMS):
    mixer.fadeOut(str(fileName),fadeOutMS)
    return fileName

@app.route('/watchdog')
def watchdog():
    mytimer = int(time.time())
    return str(mytimer)

@app.route('/startWatchdog')
def startWatchdog():
    p = subprocess.Popen(["wmctrl" ,"-r" ,"image.display", "-b" ,"add,fullscreen,above"], stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    out, err = p.communicate()
    threadEvent.set()
    threading.Thread(target=watchdogLoop).start()
    return str("true")

@app.route('/killall')
def killall():
    threadEvent.clear()
    p = subprocess.Popen(['service', 'supervisor','stop'], stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    out, err = p.communicate()
    p = subprocess.Popen(['killall', 'qlua'], stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    out, err = p.communicate()

    shutdown_server()

    p = subprocess.Popen(['killall', 'sudo'], stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    out, err = p.communicate()
    p = subprocess.Popen(['killall', 'python'], stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    out, err = p.communicate()

"""
@app.route('/setColor/<r>/<g>/<b>')
def setColor(r,g,b):
    bulb.sendColor(str(r),str(g),str(b))
    return "color set"

@app.route('/connectBulb')
def connectBulb():
    bulb.connect()
    return "connected"
"""



if __name__ == '__main__':

    #func = request.environ.get('werkzeug.server.shutdown')
    #func()
    app.run(debug=True)

