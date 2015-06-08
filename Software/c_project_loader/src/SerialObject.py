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
from PyQt5 import QtCore
from PyQt5.QtCore import QObject
# from PyQt5.QtSerialPort import QSerialPort as serial


class SerialObject(QObject):
    """
    Class to handle the boot procedure
    """

    # static
    finished = QtCore.pyqtSignal()
    message = QtCore.pyqtSignal(str)

    def __init__(self, serialPort=None, binFile=None):
        super(SerialObject, self).__init__()
        self._binFile = binFile
        self._serialPort = serialPort

    def bootTarget(self):
        """
        Executes the boot protocol
        Callback for thread's started signal.
        """
        if self._serialPort is None:
            self.message.emit("ERROR:\tUnable to access the serial port.\n")
            self.finished.emit()
            return

        if self._binFile is None:
            self.message.emit("ERROR:\tUnable to access the bin file.\n")
            self.finished.emit()
            return

        if not self._serialPort.isOpen():
            self.message.emit("ERROR:\tSerial port is not open.\n")
            self.finished.emit()
            return

        # Read bin file
        try:
            with open(self._binFile, "rb") as file:
                binData = file.read()
        except (OSError, IOError):
            self.message.emit("ERROR:\tUnable to open bin file.\n")
            self.finished.emit()
            return

        print("Executing boot protocol\n")
        self._serialPort.clear()
        self.message.emit("INFO:\tPlease, reset target.\n")

        # Get first character
        dataReady = self._serialPort.waitForReadyRead(5000)
        if not dataReady:
            self.message.emit("ERROR:\tTarget not detected.\n")
            self.finished.emit()
            return

        # Get start token
        self.message.emit("INFO:\tTarget detected.\n")
        dataRx = self._serialPort.readAll()
        while self._serialPort.waitForReadyRead(10):
            dataRx += self._serialPort.readAll()

        if dataRx != b"USB":
            self.message.emit("ERROR:\tInvalid start token.\n")
            print(dataRx)
            self.finished.emit()
            return

        # send ACK
        self.message.emit("INFO:\tStart token received: bootloading.\n")
        self._serialPort.write("ACK")

        # send bin size
        binSize = os.path.getsize(self._binFile)
        binSizeWord = str((binSize/4) - 1)
        self._serialPort.write(binSizeWord)
        self._serialPort.waitForBytesWritten(100)

        # wait for KCA
        self._serialPort.waitForReadyRead(1000)
        dataRx = self._serialPort.readAll()
        while self._serialPort.waitForReadyRead(10):
            dataRx += self._serialPort.readAll()

        if dataRx != b"KCA":
            self.message.emit("ERROR:\tBoot protocol error.\n")
            self.finished.emit()
            return

        # sending bin file
        self.message.emit("INFO:\tSending bin file. Please wait.\n")
        bytesTx = self._serialPort.write(binData)
        self._serialPort.waitForBytesWritten(5000)
        if bytesTx != binSize:
            message = "ERROR:\tTruncated data. Unable to boot target.\n"
            print(bytesTx, binSize)
            self.message.emit(message)
            self.finished.emit()
            return

        # wait for ACK
        self._serialPort.waitForReadyRead(5000)
        dataRx = self._serialPort.readAll()
        while self._serialPort.waitForReadyRead(10):
            dataRx += self._serialPort.readAll()

        if dataRx != b"ACK":
            message = "ERROR:\tUnable to boot. Processor in unknown state.\n"
            self.message.emit(message)
            self.finished.emit()
            return

        self.message.emit("INFO:\tBootloading: DONE.\n")

        self.finished.emit()

    def setPort(self, serialPort):
        """
        Change the serial port
        """
        self._serialPort = serialPort

    def setBinFile(self, binFile):
        """
        Set the binary file for boot protocol
        """
        self._binFile = binFile
