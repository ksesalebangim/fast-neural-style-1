#!flask/bin/python
from flask import Flask
import sound2
from bleBulb import *
from led2 import *
import re
import pyscreenshot as ImageGrab
import time
import os
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
app = Flask(__name__)

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
    return ""

@app.route('/playSound/<string:fileName>/fadeIn/<int:fadeInMS>')
def playSound(fileName,fadeInMS):
    mixer.play(str(fileName),fadeInMS)
    return fileName

@app.route('/stopSound/<string:fileName>')
def stopSound(fileName):
    mixer.stop(str(fileName))
    return fileName

@app.route('/fadeOut/<string:fileName>/fadeOut/<int:fadeOutMS>')
def fadeOut(fileName,fadeOutMS):
    mixer.fadeOut(str(fileName),fadeOutMS)
    return fileName
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