import pexpect
class bleBulb(object):
    def __init__(self,address):
        self.address=address.upper()
        self.gatt = pexpect.spawn('gatttool -I')

    def connect(self):
        self.gatt.sendline('connect {0}'.format(self.address))
        self.gatt.expect('Connection successful')

    def testConnection(self):
        if "[0;94m["+self.address+"]" in self.gatt.buffer:
            return True
        return False

    def sendColor(self,rHex,gHex,bHex):
        if self.testConnection():
            self.gatt.sendline('char-write-cmd 0x002e 56{0}{1}{2}00f0aa'.format(rHex,gHex,bHex))
        else:
            self.connect()
            self.sendColor(rHex,gHex,bHex)
