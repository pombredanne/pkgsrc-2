######################################################################
# Automatically generated by qmake (2.01a) Mon Jun 30 09:39:04 2008
######################################################################

TEMPLATE = app
TARGET = 
DEPENDPATH += . src
INCLUDEPATH += . src

# Input
HEADERS += src/CommandBuilder.h \
           src/CommandExecutionThread.h \
           src/Hash.h \
           src/Loading.h \
           src/ORM_AddDistroGUI.h \
           src/ORM_AddRepoGUI.h \
           src/ORM_WaitDialog.h \
           src/pstream.h \
           src/SimpleConfigFile.h \
           src/utilities.h \
           src/XOSCAR_AboutAuthorsDialog.h \
           src/XOSCAR_AboutOscarDialog.h \
           src/XOSCAR_FileBrowser.h \
           src/XOSCAR_MainWindow.h \
           src/XOSCAR_TabGeneralInformation.h \
           src/XOSCAR_TabWidgetInterface.h
FORMS += src/AboutAuthorsDialog.ui \
         src/AboutOSCARDialog.ui \
         src/AddDistroWidget.ui \
         src/AddRepoWidget.ui \
         src/FileBrowser.ui \
         src/WaitDialog.ui \
         src/xoscar_generalinformation.ui \
         src/xoscar_mainwindow.ui 
SOURCES += src/CommandBuilder.cpp \
           src/CommandExecutionThread.cpp \
           src/Hash.cpp \
           src/Loading.cpp \
           src/main.cpp \
           src/ORM_AddDistroGUI.cpp \
           src/ORM_AddRepoGUI.cpp \
           src/ORM_WaitDialog.cpp \
           src/SimpleConfigFile.cpp \
           src/utilities.cpp \
           src/XOSCAR_AboutAuthorsDialog.cpp \
           src/XOSCAR_AboutOscarDialog.cpp \
           src/XOSCAR_FileBrowser.cpp \
           src/XOSCAR_MainWindow.cpp \
           src/XOSCAR_TabGeneralInformation.cpp \
           src/XOSCAR_TabWidgetInterface.cpp
RESOURCES += xoscar_resource.qrc
