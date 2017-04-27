// lab3, dt079g
// Joel Edström (joed1300)
// p_queue.h, 2015-01-05
// A priority queue implemented as a binary heap stored in a std::vector
// Reference: http://en.wikipedia.org/wiki/Binary_heap

#ifndef __lab3__p_queue__
#define __lab3__p_queue__

#include <vector>
#include <stdexcept>


/* Templates has to be completly defined in a header file,
 * because they cant be independantly compiled in a seperate compilation unit.
 * Instead it will be instantiated into each compilation unit that uses the template,
 * with the missing type parameters filled in.
 * So multiple copies of the code will exist throughout the application (if its used by multiple compilation units)
 */

template <class T, class PredicateFunc>
class p_queue {
    /* vector that stores the heap's tree based structure level by level. Example: (vector indices)
     *          [0]
     *     [1]       [2]
     *   [3] [4]   [5]  [ ]
     * (Note that each level doesn't have to be completly filled)
     */
    std::vector<T> _heap;

    // Predicate function that determites the order of the heap
    // if this is fullfilled for all nodes, the "heap property" is fullfilled.
    PredicateFunc _pred;
    
    // helper functions for calculting indices of children and parent of a node index.
    size_t indexOfLeftChild(size_t index) {
        return (index * 2) + 1;
    }
    size_t indexOfRightChild(size_t index) {
        return (index * 2) + 2;
    }
    size_t indexOfParent(size_t index) {
        return (index - 1) / 2;
    }
    
    // binary heap "up-heap" / "bubble-up" implementation
    // restores the heap property starting from the node referenced by index, going up through parents.
    void upHeap(size_t index) {
        
        // reached the top of the tree
        // which means we have no parent and we're done
        if (index == 0)
            return;
        
        size_t parent = indexOfParent(index);
        
        // do nothing if the heap property is valid
        if (_pred(_heap[parent], _heap[index]))
            return;
        else
        {
            // swap index and parent
            std::swap(_heap[index], _heap[parent]);
        
            // recurse up to the above level
            upHeap(parent);
        }
    }
    
    // binary heap "down-heap" / "bubble-down" implementation
    // restores the heap property starting from the node referenced by index, going down through children.
    void downHeap(size_t index) {
        size_t leftIndex = indexOfLeftChild(index);
        size_t rightIndex = indexOfRightChild(index);
        
        size_t swapIndex = index;
        
        // look for children that exists, and breaks the heap property
        // pick the one that by swapping fixes the heap property
        // (the largest child in a max-heap, for example)
        if (leftIndex < _heap.size() && !_pred(_heap[swapIndex], _heap[leftIndex]))
            swapIndex = leftIndex;
        if (rightIndex < _heap.size() && !_pred(_heap[swapIndex], _heap[rightIndex]))
            swapIndex = rightIndex;
        
        
        // we found a child that when swapped with restores the heap property(at this level of the tree)
        if (swapIndex != index) {
            // swap with the child we found
            std::swap(_heap[swapIndex], _heap[index]);
            
            // recurse down the child which was changed by the swap.
            // it might need fixing up to restore heap property down the tree.
            downHeap(swapIndex);
        }

        // no swaps necessary, we're done. The heap property is restored.
    }
    
public:
    T pop() {
        if (_heap.size() > 0) {
            // save the first element of the sorted heap
            auto ret = _heap[0];
            
            // replace the first element with the last element
            auto lastElement = _heap.back(); _heap.pop_back();
            _heap[0] = lastElement;
            
            // run the downHeap algoritm on the new first element
            // to restore the heap property (make the heap sorted according to the PredicateFunc again)
            downHeap(0);
            
            return ret;
        } else
            throw std::out_of_range("the queue is empty, can't pop");
        
    }
    void push(T e) {
        // add a new lead node
        _heap.push_back(e);
        
        // call upHeap on the new leaf node, to restore the heap property
        // (it will cause it to be swapped with its parents until the heap is properly sorted again)
        upHeap(_heap.size() - 1);
    }
    int size() {
        return _heap.size();
    }
    bool empty() {
        return _heap.empty();
    }
    
    template <class InputIterator>
    void pushRange(InputIterator begin, InputIterator end) {
        for (auto it = begin; it != end; ++it) {
            push(*it);
        }
    }
};

#endif /* defined(__lab3__p_queue__) */
