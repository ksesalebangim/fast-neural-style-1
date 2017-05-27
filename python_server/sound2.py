import glob
import pygame, sys
import os

class myMixer(object):
    def __init__(self,musicPath):
        self.musicPath=musicPath
        pygame.init()
        self.sounds = self.setupFiles(self.loadFolder(self.musicPath))

    def loadFolder(self,path):
        return glob.glob(os.path.dirname(path)+"/*.ogg")

    def setupFiles(self,paths):
        sounds ={}
        for path in paths:
            fileName = path.split("/")[-1]
            #fileName = str(fileName).replace(".","_")
            sounds[fileName] = pygame.mixer.Sound(path)
        return sounds

    def play(self,fileName,fadeInMS):
        fileName = str(fileName)
        self.sounds[fileName].play(fade_ms=fadeInMS)

    def fadeOut(self,fileName,fadeOutMS):
        self.sounds[fileName].fadeout(fadeOutMS)

    def stop(self,fileName):
        self.sounds[fileName].stop()

    def stopAll(self):
        for sound in self.sounds.values():
            sound.stop()

