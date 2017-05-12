import pygame, sys

white = (255, 255, 255)

pygame.init()
clock = pygame.time.Clock()

# load sound file
sound = pygame.mixer.Sound('/home/ben/midburn/Flume.ogg')
sound2 = pygame.mixer.Sound('/home/ben/midburn/left.ogg')
print 'the sound file is', sound.get_length(), 'seconds long.'

print 'press 1 - play sound'
print 'press 2 - play sound continuously in a loop'
print 'press 3 - play sound but start with 3 seconds fade-in effect'
print 'press 4 - play sound for 5 seconds'
print 'press 5 - play sound 3 more times'
print 'press 9 - stop playing with 3 seconds fadeout effect'
print 'press 0 - stop playing instantly'

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            sys.exit()
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_1:
                sound.play()
            if event.key == pygame.K_2:
                sound.play(-1)
            if event.key == pygame.K_3:
                sound.play(-1, fade_ms=30000)
            if event.key == pygame.K_4:
                sound.play(-1, 5000)
            if event.key == pygame.K_5:
                sound.play(3)
            if event.key == pygame.K_9:
                sound.fadeout(15000)
                sound2.play(-1, fade_ms=15000)
            if event.key == pygame.K_0:
                sound.stop()
    clock.tick(20)