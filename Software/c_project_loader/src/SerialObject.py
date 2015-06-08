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
from PyQt5 import QtCore
from PyQt5.QtCore import QObject
from PyQt5.QtCore import QIODevice
from PyQt5.QtSerialPort import QSerialPort as serial


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
        """
        if self._portName is None:
            self.message.emit("ERROR:\tUnable to access the serial port.\n")
            self.finished.emit()
            return

        if self._binFile is None:
            self.message.emit("ERROR:\tUnable to access the bin file.\n")
            self.finished.emit()
            return

        port = serial(self)
        port.setPortName(self._portName)
        isOpen = port.open(QIODevice.ReadWrite)
        if not isOpen:
            self.message.emit("ERROR:\tUnable to open serial port.\n")
            self.finished.emit()
            return

        port.setBaudRate(serial.Baud115200)
        port.setDataBits(serial.Data8)
        port.setParity(serial.NoParity)
        port.setFlowControl(serial.NoFlowControl)

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

        # Info
        message = "INFO:\tBooting target.\n"
        self.message.emit(message)
        fileSize = os.path.getsize(self._binFile)
        message = "INFO:\tSize = {} bytes.\n".format(fileSize)
        self.message.emit(message)

        port.clear()
        self.message.emit("INFO:\tPlease, reset target.\n")

        # Get first character
        dataReady = port.waitForReadyRead(5000)
        if not dataReady:
            port.close()
            self.message.emit("ERROR:\tTarget not detected.\n")
            self.finished.emit()
            return

        # Get start token
        self.message.emit("INFO:\tTarget detected.\n")
        dataRx = port.readAll()
        while port.waitForReadyRead(10):
            dataRx += port.readAll()

        if dataRx != b"USB":
            port.close()
            self.message.emit("ERROR:\tInvalid start token.\n")
            print(dataRx)
            self.finished.emit()
            return

        # send ACK
        self.message.emit("INFO:\tStart token received: bootloading.\n")
        port.write("ACK")

        # send bin size
        binSize = os.path.getsize(self._binFile)
        binSizeWord = int((binSize/4) - 1)
        print(binSizeWord, hex(binSizeWord))
        binSizeWord = struct.pack('I', binSizeWord)
        print(binSizeWord)
        print(binSizeWord[0], binSizeWord[1], binSizeWord[2])
        port.write(chr(binSizeWord[0]))
        port.write(chr(binSizeWord[1]))
        port.write(chr(binSizeWord[2]))
        port.waitForBytesWritten(100)

        # wait for KCA
        port.waitForReadyRead(5000)
        dataRx = port.readAll()
        while port.waitForReadyRead(10):
            dataRx += port.readAll()

        print(dataRx)
        if dataRx != b"KCA":
            port.close()
            self.message.emit("ERROR:\tBoot protocol error.\n")
            self.finished.emit()
            return

        # sending bin file
        self.message.emit("INFO:\tSending bin file. Please wait.\n")
        bytesTx = port.write(binData)
        port.waitForBytesWritten(5000)
        if bytesTx != binSize:
            port.close()
            message = "ERROR:\tTruncated data. Unable to boot target.\n"
            print(bytesTx, binSize)
            self.message.emit(message)
            self.finished.emit()
            return

        # wait for ACK
        port.waitForReadyRead(5000)
        dataRx = port.readAll()
        while port.waitForReadyRead(10):
            dataRx += port.readAll()

        if dataRx != b"ACK":
            port.close()
            message = "ERROR:\tUnable to boot. Processor in unknown state.\n"
            self.message.emit(message)
            self.finished.emit()
            return

        port.close()
        self.message.emit("INFO:\tBootloading: DONE.\n")
        self.finished.emit()

    def setBinFile(self, binFile):
        """
        Set the binary file for boot protocol
        """
        self._binFile = binFile

    def setPortName(self, portName):
        self._portName = portName
