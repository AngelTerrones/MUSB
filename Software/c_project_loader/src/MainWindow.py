# =========================================================================
# Filename      : MainWindow.py
# Revision      : 1.0
# Author        : Angel Terrones
# Company       : Universidad Simón Bolívar
# Email         : aterrones@usb.ve
# Description   : Main UI Class
# =========================================================================

import os
import shutil
import glob
import json
import fileinput
import re
from PyQt5 import QtCore
import serial.tools.list_ports as list_ports
from PyQt5.QtCore import QSettings
from PyQt5.QtWidgets import QMainWindow, QFileDialog, QMessageBox
from PyQt5.QtGui import QIcon, QPixmap
from Ui_MainWindow import Ui_MainWindow
from SerialObject import SerialObject


class MainWindow(QMainWindow, Ui_MainWindow):
    """
    Class for the Main UI
    Basic application to (re)create C projects for the
    MUSB processor.
    """

    # static
    utilPath = os.path.abspath("../../utils")
    optimizationLevel = ["0", "1", "2", "3", "s"]

    def __init__(self):
        super(MainWindow, self).__init__()
        self._serialThread = QtCore.QThread()
        self._serialObject = SerialObject()
        self._booting = False
        self._settings = None
        self._serialObject.moveToThread(self._serialThread)
        self._setupUi()
        self.loadSerialPorts()
        self._loadSettings()
        self._connectSignalSlots()

    def closeEvent(self, event):
        """
        Close event.
        """
        if self._booting:
            title = "Exit program"
            message = "Aborting boot."
            QMessageBox.critical(self, title, message)

        self._saveSettings()

    def _setupUi(self):
        """
        Configure the interface: set window's icon,
        and initialize the default project location.
        """
        self.setupUi(self)
        self.setWindowIcon(QIcon('../Ui/c.svg'))
        self.labelIcon.setPixmap(QPixmap('../Ui/logo_musb.png'))
        self.lineEditProjectLocation.setText(os.path.expanduser("~/Documents"))

    def _connectSignalSlots(self):
        """
        Connect signals and slots
        """
        self.toolButtonLocation.clicked.connect(self.setProjectLocation)
        self.pushButtonNew.clicked.connect(self.newProject)
        self.pushButtonLoad.clicked.connect(self.loadProject)
        self.pushButtonUpdate.clicked.connect(self.updateProject)
        self.pushButtonExit.clicked.connect(self.close)
        self.pushButtonReload.clicked.connect(self.loadSerialPorts)
        self.toolButtonSeletBinFile.clicked.connect(self.selectBinFile)
        self.pushButtonBoot.clicked.connect(self.bootTarget)
        self.pushButtonClear.clicked.connect(self.textEdit.clear)

        self._serialObject.finished.connect(self._serialThread.quit)
        self._serialObject.message.connect(self.insertMessage)
        self._serialThread.started.connect(self._serialObject.bootTarget)
        self._serialThread.finished.connect(self.bootThreadFinished)

    def _loadSettings(self):
        self._settings = QSettings("Loader", "MUSB")
        projectLocation = self._settings.value("ProjectPath")
        self.lineEditProjectLocation.setText(projectLocation)
        serialPort = self._settings.value("SerialPort")
        self.comboBoxSerialPort.setCurrentText(serialPort)
        binFile = self._settings.value("BinFile")
        self.lineEditBinFile.setText(binFile)

    def _saveSettings(self):
        self._settings = QSettings("Loader", "MUSB")
        self._settings.setValue("ProjectPath",
                                self.lineEditProjectLocation.text())
        self._settings.setValue("SerialPort",
                                self.comboBoxSerialPort.currentText())
        self._settings.setValue("BinFile", self.lineEditBinFile.text())

    def createProjectFolders(self, path):
        """
        Create the project folder, and the 'src' folder.
        If the *.pro file exists inside the folder, return False
        """
        name = os.path.basename(path)
        projectFile = "{}/{}.pro".format(path, name)
        src = path + "/src"

        if os.path.exists(projectFile):
            return False

        os.makedirs(src, exist_ok=True)
        return True

    def createProjectFiles(self, path):
        """
        Create the project files:
        - src/main.c:       obvious.
        - src/boot.s:       startup code.
        - src/exception.s:  basic exception code
        - linker.ls:        basic linker file
        - makefile:         project makefile. Compiles the project, and
                            generates a listing file, an hex file for RTL
                            simulation, and a bin file for target programing.
        """
        srcFolder = path + "/src"
        templateFolder = "../../templates"  # relative to this folder.
        # copy files to src directory
        shutil.copy(templateFolder + "/main_c_template", srcFolder + "/main.c")
        shutil.copy(templateFolder + "/boot_template", srcFolder + "/boot.s")
        shutil.copy(templateFolder + "/exception_template",
                    srcFolder + "/exception.s")
        # copy files to root dir
        shutil.copy(templateFolder + "/makefile_template", path + "/makefile")
        shutil.copy(templateFolder + "/linker_template", path + "/linker.ls")

    def updateMakefileAndLinker(self, path):
        """
        Update/Regenerate makefile & linker script
        """
        templateFolder = "../../templates"
        shutil.copy(templateFolder + "/makefile_template", path + "/makefile")
        shutil.copy(templateFolder + "/linker_template", path + "/linker.ls")

        # Generate linker script
        memSize = int(self.lineEditMemorySize.text())
        dataSize = int(self.lineEditDataSegSize.text())
        memSizeText = self.lineEditMemorySize.text()
        padsize = str(memSize/4)
        textBegin = "0x{:08x}".format(0)
        textEnd = "0x{:08x}".format(memSize - dataSize - 1)
        dataBegin = "0x{:08x}".format(memSize - dataSize)
        dataEnd = "0x{:08x}".format(memSize - 1)
        stackBegin = "0x{:08x}".format(memSize)
        bootCode = "out/boot.o(.text)"
        exceptionCode = "out/exception.o(.text)"
        linker = path + "/linker.ls"
        for line in fileinput.input(linker, inplace=True):
            line = re.sub(r'%size%', memSizeText, line.rstrip())
            line = re.sub(r'%textsegbegin%', textBegin, line.rstrip())
            line = re.sub(r'%textsegend%', textEnd, line.rstrip())
            line = re.sub(r'%datasegbegin%', dataBegin, line.rstrip())
            line = re.sub(r'%datasegend%', dataEnd, line.rstrip())
            line = re.sub(r'%stackBegin%', stackBegin, line.rstrip())
            line = re.sub(r'%bootcode%', bootCode, line.rstrip())
            line = re.sub(r'%exceptioncode%', exceptionCode, line.rstrip())
            print(line)

        # Generate makefile
        makefile = path + "/makefile"
        mipsPrefix = self.lineEditCompilerPrefix.text()
        projectName = os.path.basename(path)
        optLevelComboBox = self.comboBoxOptimization.currentIndex()
        optimizationLevel = self.optimizationLevel[optLevelComboBox]
        mipsBase = self.lineEditCompilerPath.text()
        mipsBin = mipsBase + "/bin"
        for line in fileinput.input(makefile, inplace=True):
            line = re.sub(r'%prefix%', mipsPrefix, line.rstrip())
            line = re.sub(r'%bin%', mipsBin, line.rstrip())
            line = re.sub(r'%base%', mipsBase, line.rstrip())
            line = re.sub(r'%util%', self.utilPath, line.rstrip())
            line = re.sub(r'%linker%', "linker.ls", line.rstrip())
            line = re.sub(r'%optlevel%', optimizationLevel, line.rstrip())
            line = re.sub(r'%project%', projectName, line.rstrip())
            line = re.sub(r'%datasegbegin%', str(memSize - dataSize),
                          line.rstrip())
            line = re.sub(r'%padsize%', padsize, line.rstrip())
            print(line)

    def saveProject(self, path):
        """
        Create a *.pro file with the project configuration.
        """
        projectName = os.path.basename(path)
        srcFolder = path + "/src"
        cFiles = glob.glob(srcFolder + "/*.c")
        hFiles = glob.glob(srcFolder + "/*.h")
        asmFiles = glob.glob(srcFolder + "/*.s")
        projectData = {
            "Type": "MUSB-project",
            "Assembler Files": asmFiles,
            "C Files": cFiles,
            "H files": hFiles,
            "Optimization Level": self.comboBoxOptimization.currentIndex(),
            "Memory Size": int(self.lineEditMemorySize.text()),
            "Data Segment Size": int(self.lineEditDataSegSize.text())
        }
        jsonString = json.dumps(projectData, indent=4)
        projectFile = "{}/{}.pro".format(path, projectName)

        with open(projectFile, "w") as file:
            file.write(jsonString)

    def loadProjectFile(self, path):
        """
        Loads a *.pro file with the project configuration.
        TODO: check if the file does not exist.
        """
        name = os.path.basename(path)
        projectFile = "{}/{}.pro".format(path, name)
        try:
            with open(projectFile, "r") as file:
                jsonString = file.read()
        except (OSError, IOError):
            return False

        projectData = json.loads(jsonString)
        optimizationLevel = projectData["Optimization Level"]
        self.comboBoxOptimization.setCurrentIndex(optimizationLevel)
        self.lineEditMemorySize.setText(str(projectData["Memory Size"]))
        self.lineEditDataSegSize.setText(str(projectData["Data Segment Size"]))
        return True

    def setProjectLocation(self):
        """
        Create a file dialog.
        """
        title = "Select directory"
        path = self.lineEditProjectLocation.text()
        location = str(QFileDialog.getExistingDirectory(self, title, path))
        if location is "":
            return
        self.lineEditProjectLocation.setText(location)

    def newProject(self):
        """
        Creates a new C project targeting the MUSB processor
        with indicated configuration.
        Ask the user for the project location
        """
        location = self.lineEditProjectLocation.text()
        projectName = os.path.basename(location)

        if location is "":
            QMessageBox.critical(self, "New project error",
                                 "Project location is empty.")
            return

        folderCreated = self.createProjectFolders(location)

        if not folderCreated:
            title = "New project error"
            message = "Project '{}' exists at {}".format(projectName, location)
            QMessageBox.critical(self, title, message)
            return

        self.createProjectFiles(location)
        self.updateMakefileAndLinker(location)
        self.saveProject(location)
        self.lineEditBinFile.setText("{}/bin/{}.bin".format(location,
                                                            projectName))
        QMessageBox.information(self, "Information", "Project created.")

    def loadProject(self):
        """
        Loads a existing C project targeting the MUSB processor.
        """
        path = self.lineEditProjectLocation.text()
        name = os.path.basename(path)
        loaded = self.loadProjectFile(path)
        if not loaded:
            title = "Load project error"
            projectName = os.path.basename(path)
            message = "Unable to load '{}' project at {}".format(projectName,
                                                                 path)
            QMessageBox.critical(self, title, message)
            return

        self.lineEditBinFile.setText("{}/bin/{}.bin".format(path, name))

        QMessageBox.information(self, "Information",
                                "Project '{}' loaded.".format(name))

    def updateProject(self):
        """
        Update the selected project when:
        - New optimization level.
        - New memory configuration.
        """
        path = self.lineEditProjectLocation.text()
        name = os.path.basename(path)
        self.updateMakefileAndLinker(path)
        self.saveProject(path)
        QMessageBox.information(self, "Information",
                                "Project '{}' updated.".format(name))

    def loadSerialPorts(self):
        """
        Get a list of available serial ports.
        """
        self.comboBoxSerialPort.clear()

        try:
            listPorts = list_ports.comports()  # [name, pretty name, info]
        except:
            print("ERROR: Can't get com ports.")
            return

        # Hide ports with no info
        for port in listPorts:
            if port[2] != 'n/a':
                self.comboBoxSerialPort.addItem(port[0])

    def selectBinFile(self):
        """
        Select bin file.
        By default, use the bin from the current open project
        """
        path = self.lineEditProjectLocation.text()
        title = "Open bin file"
        filterText = "MUSB binary file (*.bin)"
        binFile = QFileDialog.getOpenFileName(self, title, path + "/bin",
                                              filterText)
        # binFile is a tuple. The filename is the first item
        if binFile[0] is "":
            return

        self.lineEditBinFile.setText(binFile[0])

    def bootTarget(self):
        """
        Starts the serial thread.
        """
        binFile = self.lineEditBinFile.text()
        if not os.path.exists(binFile):
            title = "Boot error"
            message = "Unable to open {} file.".format(binFile)
            QMessageBox.critical(self, title, message)
            return

        self.pushButtonBoot.setDisabled(True)

        # start thread
        portName = self.comboBoxSerialPort.currentText()
        self._serialObject.setPortName(portName)
        self._serialObject.setBinFile(binFile)
        self._serialThread.start()
        self._booting = True

    def bootThreadFinished(self):
        """
        Enable the boot pushbutton when the serial thread
        finish its execution.
        """
        self.pushButtonBoot.setEnabled(True)
        self._booting = False

    def insertMessage(self, message):
        """
        Insert message in the text log
        """
        self.textEdit.insertPlainText(message)

if __name__ == '__main__':
    print("MainWindow Class")
