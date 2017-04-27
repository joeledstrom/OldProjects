# -*- coding: utf-8 -*-
# Copyright Joel Edström 2014

import threading


# Simple class that wraps a mutex lock to implement a Fork.
class Fork:
    
    def __init__(self):
        self.__lock = threading.Lock()
        
    def grab(self):
        self.__lock.acquire()
        
    def release(self):
        self.__lock.release()
        
    # check if the lock fork is free, by using a non blocking 
    # acquire() and then if successful: immediately releasing it.
    def free(self):
        if (self.__lock.acquire(False)):
            self.__lock.release()
            return True
        else:
            return False