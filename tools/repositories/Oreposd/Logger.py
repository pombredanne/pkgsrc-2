###################################################################
# Copyright (c) 2007 INRIA-IRISA,
#                    Jean Parpaillon <jean.parpaillon@irisa.fr>
#                    All rights reserved
# For license information, see the COPYING file in the top level
# directory of the source
###################################################################

import os
import datetime

class Logger(object):
    """ Logger 
    """
    ERROR = 0
    INFO  = 1
    DEBUG = 2
    TRACE = 3

    __instance = None
    __level = ERROR

    __dateformat__ = "%b %d %H:%M:%S"

    def __new__ (cls):
        if cls.__instance is None:
            cls.__instance = object.__new__(cls)
        return cls.__instance

    def level(self, lvl):
        """ Set verbosity level
        """
        self.__level = lvl

    def isError(self):
        return self.__level >= Logger.ERROR
        
    def error(self, msg):
        print "%s [ERROR] %s" % (datetime.datetime.now().strftime(self.__dateformat__), msg)

    def isInfo(self):
        return self.__level >= Logger.INFO
        
    def info(self, msg):
        if self.__level >= Logger.INFO:
            print "%s [INFO] %s" % (datetime.datetime.now().strftime(self.__dateformat__), msg)

    def isDebug(self):
        return self.__level >= Logger.DEBUG
        
    def debug(self, msg):
        if self.__level >= Logger.DEBUG:
            print "%s [DEBUG] %s" % (datetime.datetime.now().strftime(self.__dateformat__), msg)

    def isTrace(self):
        return self.__level >= Logger.TRACE
        
    def trace(self, msg):
        if self.__level >= Logger.TRACE:
            print "%s [TRACE] %s" % (datetime.datetime.now().strftime(self.__dateformat__), msg)
