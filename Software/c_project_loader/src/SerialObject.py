# =========================================================================
# Filename      : SerialObject.py
# Revision      : 1.0
# Author        : Angel Terrones
# Company       : Universidad Simón Bolívar
# Email         : aterrones@usb.ve
# Description   : Serial Object.
#                 Handles communication with the target
# =========================================================================

import os
import struct
import serial
from PyQt5 import QtCore
from PyQt5.QtCore import QObject


class SerialObject(QObject):
    """
    Class to handle the boot procedure
    """

    # static
    finished = QtCore.pyqtSignal()
    message = QtCore.pyqtSignal(str)

    def __init__(self):
        super(SerialObject, self).__init__()
        self._binFile = None
        self._portName = None

    def bootTarget(self):
        """
        Executes the boot protocol
        Callback for thread's started signal.

        MUSB Boot Protocol Description:

        The protocol is over a COM (serial) port, 115200 bauds, 8N1, no parity.
        1. At reset, the target/UART-bootloader sends "USB". The Master Reset
           is asserted by this module.
        2. The programmer/uploader sends the size, in words, of the bin file,
           minus 1, with timeout of 1 second. After 1 second, it will release
           the Master Reset, and enter Slave Mode.
           The size is 18-bits (3 bytes). The size is sent from low-order to
           high-order bytes (Little-Endian).
        4. The target echoes the 3 bytes received, to confirm that the
           bootloader is listening.
        5. The programmer/uploader sends the bin file (data). The target will
           echo each byte to confirm
           proper functioning.
        7. The target boots from memory when the last byteis received.
        """
        if self._portName is None:
            self.message.emit("ERROR:\tUnable to access the serial port.\n")
            self.finished.emit()
            return

        if self._binFile is None:
            self.message.emit("ERROR:\tUnable to access the bin file.\n")
            self.finished.emit()
            return

        try:
            port = serial.Serial(self._portName, 115200, timeout=5,
                                 writeTimeout=5)
        except Exception as e:
            print(e)
            print("Unable to open serial port {}".format(self._portName))
            self.message.emit("ERROR:\tUnable to open serial port.\n")
            self.finished.emit()
            return

        isOpen = port.isOpen()
        print(isOpen)
        if not isOpen:
            self.message.emit("ERROR:\tUnable to open serial port.\n")
            self.finished.emit()
            return

        # ----------------------------------------------------------------------
        # Read bin file
        try:
            with open(self._binFile, "rb") as file:
                binData = file.read()
        except (OSError, IOError):
            port.close()
            self.message.emit("ERROR:\tUnable to open bin file.\n")
            self.finished.emit()
            return

        print("Executing boot protocol\n")

        # ----------------------------------------------------------------------
        # Info
        message = "INFO:\tBooting target.\n"
        self.message.emit(message)
        fileSize = os.path.getsize(self._binFile)
        message = "INFO:\tSize = {} bytes.\n".format(fileSize)
        self.message.emit(message)

        self.message.emit("INFO:\tPlease, reset target.\n")

        # ----------------------------------------------------------------------
        # Get 'USB'
        dataRx = port.read(3)
        print(dataRx)
        if(len(dataRx) < 3):
            port.close()
            self.message.emit("ERROR:\tTarget not detected.\n")
            self.finished.emit()
            return

        self.message.emit("INFO:\tTarget detected.\n")
        if dataRx != b'USB':
            print(dataRx)
            port.close()
            self.message.emit("ERROR:\tInvalid start token.\n")
            self.finished.emit()
            return

        self.message.emit("INFO:\tStart token received: bootloading.\n")

        # ----------------------------------------------------------------------
        # send bin size
        binSize = os.path.getsize(self._binFile)
        binSizeWord = int((binSize/4) - 1)
        binSizeWord = struct.pack('I', binSizeWord)
        port.write(bytes([binSizeWord[0]]))
        port.write(bytes([binSizeWord[1]]))
        port.write(bytes([binSizeWord[2]]))

        # ----------------------------------------------------------------------
        # Check echo size
        echoSize = port.read(3)
        if echoSize != binSizeWord[0:3]:
            print(echoSize)
            port.close()
            self.message.emit("ERROR:\tWrong echo (size).\n")
            self.finished.emit()
            return

        # ----------------------------------------------------------------------
        # Send bin file
        self.message.emit("INFO:\tSending bin file. Please wait.\n")
        counter = 0
        bytesTx = 0
        while counter < binSize:
            byteSend = bytes([binData[counter]])
            bytesTx = bytesTx + port.write(byteSend)
            byte = port.read(1)
            if byte != bytes([binData[counter]]):
                message = "ERROR:\tError {}: {} != {}".format(counter, byte,
                                                              byteSend)
                print(message)
                self.message.emit(message)
            counter = counter + 1

        if bytesTx != binSize:
            print(bytesTx, binSize)
            port.close()
            message = "ERROR:\tTruncated data. Unable to boot target.\n"
            self.message.emit(message)
            self.finished.emit()
            return

        # ----------------------------------------------------------------------
        # Exit
        port.close()
        self.message.emit("INFO:\tBootloading: DONE.\n")
        self.finished.emit()

    def setBinFile(self, binFile):
        """
        Set the binary file for boot protocol
        """
        self._binFile = binFile

    def setPortName(self, portName):
        """
        Set the serial port to use.
        """
        self._portName = portName
