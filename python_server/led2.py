import serial, time
class myled(object):
    def __init__(self):
        self.ser = serial.Serial()
        self.ser.port = "/dev/ttyUSB0"
        # ser.port = "/dev/ttyS2"
        self.ser.baudrate = 115200
        self.ser.bytesize = serial.EIGHTBITS  # number of bits per bytes
        self.ser.parity = serial.PARITY_NONE  # set parity check: no parity
        self.ser.stopbits = serial.STOPBITS_ONE  # number of stop bits
        # ser.timeout = None          #block read
        self.ser.timeout = 1  # non-block read
        # ser.timeout = 2              #timeout block read
        self.ser.xonxoff = False  # disable software flow control
        self.ser.rtscts = False  # disable hardware (RTS/CTS) flow control
        self.ser.dsrdtr = False  # disable hardware (DSR/DTR) flow control
        self.ser.writeTimeout = 2  # timeout for write
        self.ser.open()

    def setColors(self,rgbArray):
        rgbArray = rgbArray.split(",")
        for x in xrange(0,len(rgbArray)):
            rgbArray[x]=chr(int(str(rgbArray[x])))
        data = "".join(rgbArray)
        if self.ser.isOpen():
            self.ser.flushInput()  # flush input buffer, discarding all its contents
            self.ser.flushOutput()  # flush output buffer, aborting current output
            self.ser.write(data)
            time.sleep(0.05)  # give the serial port sometime to receive the data

