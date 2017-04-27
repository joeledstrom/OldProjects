#!/usr/bin/env python -B
# -*- coding: utf-8 -*-
# -B option avoids creating those pesky .pyc files

# Copyright Joel Edström 2014

import philosopher
from philosopher import Philosopher, PhilosopherEngine
import threading
import time
import sys

### Different solutions to the problem implemented as subclasses of Philosopher:

class Deadlocking(Philosopher):
    
    def grabForks(self):
        self.leftFork.grab()
        #time.sleep(0.01) # increase chance of deadlock
        self.rightFork.grab()
        
    def releaseForks(self):
        self.leftFork.release()
        self.rightFork.release()

class OddEven(Philosopher):
    
    def grabForks(self):
        if (self.index % 2 == 0):
            self.leftFork.grab()
            self.rightFork.grab()
        else:
            self.rightFork.grab()
            self.leftFork.grab()
        
    def releaseForks(self):
        self.leftFork.release()
        self.rightFork.release()
            
            
class SimpleMutex(Philosopher):
    lock = threading.Lock()
    
    def grabForks(self):
        self.lock.acquire()
        self.leftFork.grab()
        self.rightFork.grab()
        
    def releaseForks(self):
        self.leftFork.release()
        self.rightFork.release()
        self.lock.release()

class ConditionVariable(Philosopher):
    lock_and_cv = threading.Condition()
    
    def grabForks(self):
        with self.lock_and_cv:
            while not (self.leftFork.free() and self.rightFork.free()):
                self.lock_and_cv.wait()

                    
            self.leftFork.grab()
            self.rightFork.grab()
            
        
    def releaseForks(self):
        with self.lock_and_cv:
            self.leftFork.release()
            self.rightFork.release()
            
            self.lock_and_cv.notifyAll()


# By listing the solution classes in this array, the menu system below will
# able to find and test them.
solutions = [Deadlocking, OddEven, SimpleMutex, ConditionVariable]

# get some parameters then run the test, helper function to the menu system.
def testSolution(solution):
    runtime = 5
    num = 5
    maxSleep = 0.02
    
    
    try: runtime = input("Run test for? [5 seconds] ")
    except SyntaxError: pass
    
    try: num = input("Number of philosophers? [5] ")
    except SyntaxError: pass
    
    try: maxSleep = input("Max eat/think time? [0.02 seconds]  ")
    except SyntaxError: pass
    
    engine = PhilosopherEngine(solution, int(num), runtime, maxSleep)
    
    print "Running..."
    engine.start()

# A simple menu system
while True:
    print "\nThe Dining Philosophers Problem - Testing Framework 1.0"
    print "Solution attempts avaiable:"
    
    try:
        for i in range(0, len(solutions)):
            print i, solutions[i].__name__
            
        print str(len(solutions)) + " Quit application."
        choice = input("Which one would you like to run? ")  
        
        
        if choice < 0 or choice > len(solutions):
            raise ValueError
        elif (choice == len(solutions)):
            sys.exit(0)
        else:
            testSolution(solutions[choice])
              
    except (ValueError, NameError):
        print "Bad input."
        
            
            
        





