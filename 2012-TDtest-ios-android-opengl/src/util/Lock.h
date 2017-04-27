#ifndef TD_UTIL_LOCK_H
#define TD_UTIL_LOCK_H



#include <pthread.h>
#include <stdexcept>


#define DISALLOW_COPY_AND_ASSIGN(TypeName) \
TypeName(const TypeName&);               \
void operator=(const TypeName&)

namespace tdutil {
    
    
    
    
    
    class Lock {
        friend class AcquiredLock;
        DISALLOW_COPY_AND_ASSIGN(Lock);
        
        pthread_mutex_t mutex;
        pthread_cond_t cond;
        
        void lock() {
            pthread_mutex_lock(&mutex);
        }
        
        void unlock() {
            pthread_mutex_unlock(&mutex);
        }
        
        void signal() {
            pthread_cond_signal(&cond);
        }
        
        void wait() {
            pthread_cond_wait(&cond, &mutex);
        }
        
        
    public:
        Lock() {
            int err = pthread_mutex_init(&mutex, NULL);
            if (err)
                throw std::runtime_error("Couldn't create Lock");
    
            err = pthread_cond_init(&cond, NULL);
            if (err) {
                pthread_mutex_destroy(&mutex); // exception safe
                throw std::runtime_error("Couldn't create Lock");
            }
            
            
        }
        
        
        
        ~Lock() {
            pthread_mutex_destroy(&mutex);
            pthread_cond_destroy(&cond);
        }
        
        
    };
    
    class AcquiredLock {
        DISALLOW_COPY_AND_ASSIGN(AcquiredLock);
        Lock& _l;
    public:
        AcquiredLock(Lock& l) : _l(l) {
            _l.lock();
        }
        
        void wait() {
            _l.wait();
        }
        
        void signal() {
            _l.signal();
        }
        
        ~AcquiredLock() {
            _l.unlock();
        }
    };
    
    
    
    
}


#endif