package foo.mandelbrot.util;

/**
 * Tuple is a class that can store two reference types of any type.
 * Its an immutable and generic class.
 */
public class Tuple<A, B> {
    // final(immutable after having been assigned to once) fields
    // of generic type A, and B (meaning they can both have any type, seperatly from each other)
    public final A item1;
    public final B item2;
    
    /**
     * The contructor saves references to the items passed to it.
     * You can't directly pass primitive types to it, but the compiler will make it look like it,
     * using autoboxing(it will automatically for example do new Integer(5); if you pass it 5)
     *
     * @param item1 a reference type of type A
     * @param item2 a reference type of type B
     */
    public Tuple(A item1, B item2) {
        this.item1 = item1;
        this.item2 = item2;
    }
}