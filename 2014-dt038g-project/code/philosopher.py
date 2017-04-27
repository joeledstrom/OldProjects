# -*- coding: utf-8 -*-
# Copyright Joel Edström 2014

from fork import Fork
from threading import Thread
import time
import random


# Abstract Philosopher class that's used to test different solutions to
# the Dinings philosophers problem
class Philosopher:
    def __init__(self, index, leftFork, rightFork):
        self.index = index
        self.leftFork = leftFork
        self.rightFork = rightFork
        self.timeBlocking = 0.0
        self.timeEating = 0.0
        self.timeThinking = 0.0
    
    def grabForks(self):
        raise NotImplementedError()
        
    def releaseForks(self):
        raise NotImplementedError()

# Dining philosophers problem testing framework
# Parameters:
#     philosopherClass: subclass of the abstract class Philosopher that
#                       implements a certain solution to the problem.
#     count:            number of philosophers(and forks) to simulate
#     minRuntime:       run for at least this long (seconds)
#     maxEatThinkTime:  each philosopher will eat or think for at most this 
#                       long each time they do it. (seconds) 
class PhilosopherEngine:
    
    def __init__(self, philosopherClass, count, minRuntime, maxEatThinkTime):
        self.philosopherClass = philosopherClass
        self.count = count
        self.minRuntime = minRuntime
        self.maxEatThinkTime = maxEatThinkTime
    
    
    # Run this method to start the simulation
    def start(self):
        ## create the forks
        self.forks = map(lambda i: Fork(), range(0, self.count))
                
        # create the philosophers and pass them their index and
        # their left- and righthand forks
        self.philosophers = []
        for i in range(0, self.count):
            self.philosophers.append(self.philosopherClass(i, self.__leftFork(i), self.__rightFork(i)))
        
        # create a thread per philosopher
        self.threads = map(lambda p: Thread(target = self.__philosopherMain, args = [p]), self.philosophers)
        
        # start the actual simulation    
        totalRuntime = self.__run()
        
        #display results    
        self.__displayRuntimes(totalRuntime)
    
    
    # helper methods for printing the results
    def __displayRuntimes(self, runtime):
        
        out = ""
        
        sumBlocking = 0
        sumThinking = 0
        sumEating = 0
        
        out += "     Philosopher implementation: " + self.philosopherClass.__name__ + "\n"
        out += "     Times spent (s) during a total runtime of " + "%.2f"%runtime + " s\n"
        out += "     Blocking\tEating\tThinking\tProductive %\n"
        
        for p in self.philosophers:
            
            sumBlocking += p.timeBlocking
            sumThinking += p.timeThinking
            sumEating += p.timeEating
            
            productiveTime = p.timeThinking + p.timeEating
            productivePercent =  productiveTime / runtime * 100
            
            out += str(p.index) + ":   "
            out += "%.2f" % p.timeBlocking + "\t"
            out += "%.2f" % p.timeEating + "\t" 
            out += "%.2f" % p.timeThinking + "\t\t"
            out += "%.0f" % productivePercent + "%\n"
        
        sumProductive = sumThinking + sumEating
        prodPercent = "%.0f" % (sumProductive / runtime / self.count  * 100)
        out += "sum: " + "%.2f" % sumBlocking + "\t"+ "%.2f" % sumEating + "\t"
        out += "%.2f" % sumThinking + "\t\t" + prodPercent + "%\n"
        
        print out
     
    # starts all philosopher threads and then waits for them to finish
    # measures the total time it takes, and returns it.
    def __run(self):
        start = time.time()
        
        for t in self.threads:
            t.start()
            
        for t in self.threads:
            t.join()
            
        return time.time() - start
       
    # return the fork to the left of index    
    def __leftFork(self, index):
        assert(index >= 0 and index < self.count)
        
        return self.forks[index]
    
    # return the fork to the right of index
    def __rightFork(self, index):
        assert(index >= 0 and index < self.count)
        
        if index == (self.count - 1):
            return self.forks[0]
        else:
            return self.forks[index + 1]


    # Thread main function for all philosophors
    def __philosopherMain(self, philosopher):
        stopAt = time.time() + self.minRuntime
         
        while time.time() < stopAt:
            
            # Think (sleep) for random time (at most maxEatThinkTime)
            # and add the time spent thinking to timeThinking
            thinkFor = random.random() * self.maxEatThinkTime
            time.sleep(thinkFor)
            philosopher.timeThinking += thinkFor
            
            # The philosopher is hungry, time how long it takes until he/she 
            # start eating, then add that time to timeBlocking
            start = time.time()
            philosopher.grabForks()
            philosopher.timeBlocking += time.time() - start
            
            # Eat for random time (at most maxEatThinkTime)
            # and add the time spent eating to timeEating
            eatFor = random.random() * self.maxEatThinkTime
            time.sleep(eatFor)
            philosopher.timeEating += eatFor
            
            ## done eating for the time being, release forks
            philosopher.releaseForks()
            

