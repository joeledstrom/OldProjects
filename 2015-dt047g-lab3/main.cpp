// lab3, dt079g
// Joel Edström (joed1300)
// main.cpp, 2015-01-05
// main function that tests p_queue using a simple stock market simulation.

#include <random>
#include <iostream>
#include <vector>
#include "p_queue.h"



struct Order {
    std::string name;
    int price;
};

struct OrderSort {
    bool operator()(const Order& a1, const Order& a2){
        return a1.price < a2.price;
    }
};


// use the new random engine from <random> (C++11)
std::random_device rd;
std::mt19937 engine(rd());

std::vector<Order> generateRandomOrders(std::string name, int count, int min, int max) {
  
    std::vector<Order> orders;
    
    // setup a random distribution between for the range [min, max]
    std::uniform_int_distribution<int> between(min,max);
    
    for (int i = 0; i < count; ++i) {
        
        // use the random engine to generate a number in the distribution between
        int randomPrice = between(engine);
        
        Order order {name, randomPrice};
        orders.push_back(order);
    }
    
    return orders;
}



int main(int argc, const char * argv[]) {
    
    p_queue<Order, OrderSort> sellQueue;
    p_queue<Order, OrderSort> buyQueue;
    
    auto eriksSellOrders = generateRandomOrders("Erik Pendel", 7, 15, 30);
    auto eriksBuyOrders = generateRandomOrders("Erik Pendel", 7, 15, 30);
    auto jarlsSellOrders = generateRandomOrders("Jarl Wallenburg", 7, 15, 30);
    auto jarlsBuyOrders = generateRandomOrders("Jarl Wallenburg", 7, 15, 30);
    auto jockesSellOrders = generateRandomOrders("Joakim von Anka", 7, 15, 30);
    auto jockesBuyOrders = generateRandomOrders("Joakim von Anka", 7, 15, 30);
    
    sellQueue.pushRange(eriksSellOrders.cbegin(), eriksSellOrders.cend());
    buyQueue.pushRange(eriksBuyOrders.cbegin(), eriksBuyOrders.cend());
    
    sellQueue.pushRange(jarlsSellOrders.cbegin(), jarlsSellOrders.cend());
    buyQueue.pushRange(jarlsBuyOrders.cbegin(), jarlsBuyOrders.cend());
   
    sellQueue.pushRange(jockesSellOrders.cbegin(), jockesSellOrders.cend());
    buyQueue.pushRange(jockesBuyOrders.cbegin(), jockesBuyOrders.cend());
    
    
    int transactionNumber = 1;
    
    while(!sellQueue.empty() && !buyQueue.empty()) {
        auto sellOrder = sellQueue.pop();
        auto buyOrder = buyQueue.pop();
        
        // deal found
        if (sellOrder.price <= buyOrder.price) {
            std::cout << "TRANS_NO: " << transactionNumber++
                      << " SELLER: " << sellOrder.name
                      << " BUYER: " << buyOrder.name
                      << " PRICE: " << sellOrder.price
                      << std::endl;
        } else {
            // put back the sell order into the queue
            // to give the next buyOrder a chance to buy it.
            sellQueue.push(sellOrder);
        }
    }
    
    
    // Uncomment to test p_queue on a queue of ints.
    /*
    p_queue<int, std::greater<int>> testQ;
    
    std::vector<int> n {7,6,8,4,2,1,5,8};
    testQ.pushRange(n.cbegin(), n.cend());
    
    while (!testQ.empty()) {
        auto x = testQ.pop();
        std::cout << x << std::endl;

    }*/
    
    return 0;
}
