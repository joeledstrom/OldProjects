package foo.mandelbrot.util;

/** 
 * Complex is a class describing a complex number.
 * 
 * NOTES:
 * - only added the methods i'm guessing is needed for this app.
 * - high performance tweaks (generally considered bad form):
 *      1. mutable  (needed for 2)
 *      2. add/multiply-With  (math operators that writes the result to the reciever)
 *      3. public fields
 *
 */
public class Complex implements Cloneable {

    /**
     * the real part of the complex number
     */
    public double re;
    
    /**
     * the imaginary part of the complex number
     */
    public double im;
    
    // constructors
    public Complex() {}
    public Complex(double re, double im) {
        this.re = re;
        this.im = im;
    }
    
    
    /**
     * Add this number with another complex number, and store the results in "this".
     * 
     * @param other the number to add itself with.
     * @return returns itself so that you can chain methods on one complex number
     */
    public Complex addWith(Complex other) {
        re += other.re;
        im += other.im;
        
        return this; // for method chaining
    }
    
    /**
     * Change this number to itself to the power of two.
     *
     * @return returns itself so that you can chain methods on one complex number
     */
    public Complex powerOfTwo() {
        // need a copy of "re" to preserve the original value for the "im" calculation.
        double reCopy = re;
        
        // the simplification of taking a complex number to the power of two
        // got these formulas by pen and paper by simplifying: (a+bi)*(a+bi)
        // according to the rules of complex number multiplication
        re = re*re - im*im;
        im = 2*reCopy*im;
        
        return this; // for method chaining
    }
    
    
    /** 
     * Calculate the absolute value of this complex number.
     * Also called sometimes called magnitude, norm, or maybe length(in the complex space).
     *
     * @return the absolute value of the complex number
     */
    public double abs() {
        return Math.sqrt(re*re + im*im);
    }
    
    // same as above but squared, used for performance reasons in the main renderer loop
    // because Math.sqrt is a pretty slow function
    public double squaredAbs() {
        return re*re + im*im;
    }
    
    
    /**
     * Return a string respresentation of this number.
     * mainly used for so called "printf" debugging.
     *
     * @return a string describing the complex number
     */
    public String toString() {    
        return String.format("Complex Number: (%f, %fi)", re, im);
    }
}
