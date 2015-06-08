#!/usr/bin/python3
#==================================================================================================
# Filename      : project.py
# Revision      : 1.0
# Author        : Angel Terrones
# Company       : Universidad Simón Bolívar
# Email         : aterrones@usb.ve
# Description   : Main
#==================================================================================================

import sys
from PyQt5.QtWidgets import QApplication
from MainWindow import MainWindow

def main():
    """
    Start the main application
    """
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec_())

if __name__ == '__main__':
    main()
