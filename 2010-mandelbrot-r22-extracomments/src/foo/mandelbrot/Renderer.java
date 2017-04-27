package foo.mandelbrot;



import foo.mandelbrot.util.*;
import java.awt.*;
import java.awt.image.*;
import java.awt.geom.*;
import java.awt.color.*;
import java.awt.event.*;
import javax.swing.*;
import java.util.concurrent.*;
import java.util.ArrayList;

/**
 * Mandelbrot renderer.
 * has been extented to contain both a synchronous and asynchronous renderer,
 * which causes a bit of a mess, should probably be seperated into seperate classes 
 * 
 * the algoritm used found here:
 *     http://davis.wpi.edu/~matt/courses/fractals/mendel.html
 *
 *
 */
public class Renderer {
    
    // generate a periodic color spectrum, that can be shared by all instances
    // the colors are stored 3 bytes at a time(3 bytes per color, RGB)
    private static final byte[] spectrum = generateSpectrum();
    
    
    private final boolean       synchronous;
    private BufferedImage[]     image;
    
    // used by syncRenderer (synchronous == true)
    private int                 roughness;
    private int                 lastRoughness;
    private Dimension           lastSize;
    private byte[]              pixels;
    private long                recordedStartTime;
    
    // used by asyncRenderer (synchronous == false)
    private int                 threads;
    private ExecutorService     executor;
    private Timer               timer;
    private Object              asyncRenderingInProgressLock = new Object();
    private volatile boolean    tryToAbortFlag;
    private Listener            asyncListener;
    private Rectangle[]         tileFrame;
    private volatile boolean    waitingForPaint;
    
    /**
     * Renderer.Listener interface - implemented by users of this class
     * if they use it in async mode, to be notified when its done rendering.
     */
    public interface Listener {
        
        // called on listener when we're ready to get a call to async paint()
        // or skipPaint() to scrap the data
        // pass along the size and complexFrame we've used to generate the image.
        public void readyForPainting(Dimension size, Rectangle2D.Double complexFrame);
    }
    
    /**
     * Generates a periodic color spectrum of 128 colors.
     * 
     * @return a byte array containing the colors in order, each byte triple represents one color(RGB).
     */
    private static byte[] generateSpectrum() {
        final int N = 128;
        byte[] spec = new byte[N*3];
        
        for(int i=0; i<N; i++) {
            // generate a color using the HSB color model, with the hue(first @param) differing
            // max saturation(second @param) and max brightness(third @param)
            int color = Color.HSBtoRGB(i/(float)N, 1, 1);
            
            // shift out the individual RGB values from the integer
            // RIGHTSHIFT with multiples of 8(8bits/byte) to put each color in the rightmost bits(0-7)
            // AND with 0xFF to exclude all bits but bits 0-7
            spec[i*3]       = (byte) ((color >> 16) & 0xFF);
            spec[i*3 + 1]   = (byte) ((color >> 8) & 0xFF);
            spec[i*3 + 2]   = (byte) (color & 0xFF);
        }
        
        return spec;
    }
    
    /**
     * Private constructor.
     * only way to set the value of synchronous.
     * private so that users cant create broken instances of this class.
     */
    private Renderer(boolean synchronous) {
        this.synchronous = synchronous;
    }
    
    /** Factory method for creating an asynchronous renderer instance.
     *
     * @param threaded if true, try to scale to multiple CPUs.
     * @param asyncListener reference to something implementing the Renderer.Listener interface
     *                      used by the renderer to notify when its done rendering
     * @return return the created renderer instance
     */
    public static Renderer createAsyncRenderer(boolean threaded, Renderer.Listener asyncListener) {
        Renderer r = new Renderer(false);
        r.asyncListener = asyncListener;
        
        // if (threaded) set the number of threads to the numberOfCPUs in the machine, else 1
        r.threads = threaded ? Runtime.getRuntime().availableProcessors() : 1;
        
        // create a new threadpool with the number of threads specified above
        r.executor = Executors.newFixedThreadPool(r.threads);
        
        // create arrays of empty(just nulls) (BufferedImage/Rectangle)-references, with length = r.threads
        r.image = new BufferedImage[r.threads];
        r.tileFrame = new Rectangle[r.threads];
        
        return r;
    }
    
    /** Factory method for creating a synchronous renderer instance.
     *
     * @return return the created renderer instance
     */
    public static Renderer createSyncFastRenderer() {
        Renderer r = new Renderer(true);
        
        // set initial roughness to 8
        // this will later automatically depending on how long it takes to render
        r.roughness = 8;
        
        // basically just reuse the BufferedImage[] field used by the async renderer
        // but here only to store one image reference
        r.image = new BufferedImage[1];
        
        return r;
    }
    
    
    /**
     * startAsyncRender - basically the main method of the asyncControlThread.
     * 
     * @param size the size in pixels of the image generated
     * @param complexFrame the rectangle in Complex space to be rendered
     * @param iterations max number of iterations per pixel
     */
    private void startAsyncRender(final Dimension size, final Rectangle2D.Double complexFrame, int iterations) {
        
        // setting this flag to true, gives a message to currently running rendering threads to stop
        tryToAbortFlag = true;
        
        // only allow one asyncControlThread at a time (critical section)
        synchronized (asyncRenderingInProgressLock) {
            
            // make sure finished renderings has fully been drawn before starting to render again
            while (waitingForPaint) {
                try {
                    asyncRenderingInProgressLock.wait();
                } catch (InterruptedException e) {
                    System.err.println(e); // should not happen in my app, since i dont use Thread.interrupt()
                }
            }
                    
            // restore this flag, so that we can render without stopping ourselves
            tryToAbortFlag = false;
            
            
                    
            // basically divide up the image size we're ordered to render, into almost equally sized segments
            int totalHeightLeft = size.height;
            int heightPerTile = size.height / threads;
            
            for (int i=0; i<threads; i++) {
                tileFrame[i] = new Rectangle();
                
                // the segments will be segmented along the Y axis, so the X position and width will be the same
                // as the full image size 
                tileFrame[i].x = 0;
                tileFrame[i].width = size.width;
                
                // calculate the y position of the tile
                tileFrame[i].y = heightPerTile * i;
                
                // if its the last tile, use the totalHeightLeft as the tile height
                // else use heightPerTile
                tileFrame[i].height = (i == threads-1) ? totalHeightLeft : heightPerTile;
                
                // decrement totalHeightLeft by heightPerTile (the height used by the just created tile)
                // this is needed when we calculate the last tile, if it gets uneven.
                totalHeightLeft -= heightPerTile;
            }
            
            
            // create an empty list of Future references
            // a Future is used to check the status of a running/completed task running on an ExecutorService
            // and optionally get a return value from such a task
            ArrayList<Future> futureList = new ArrayList<Future>();
            
            // start rendering in parallel
            for (int i=0; i<threads; i++) {
                
                // make some final copies of some variables so that we can access them from within the inner class
                final int index = i;
                final int iters = iterations;
                final Dimension tileSize = tileFrame[i].getSize();
                
                // calculate the part of the complexFrame this particular 
                // task is supposed to render based on the tileFrames.
                double pixelToComplexFactor =  complexFrame.height/size.height;
                final Rectangle2D.Double rect = new Rectangle2D.Double();
                rect.x = complexFrame.x;
                rect.y = complexFrame.y + tileFrame[i].y * pixelToComplexFactor;
                rect.width = complexFrame.width;
                rect.height = tileFrame[i].height * pixelToComplexFactor;
                
                // - declare an anonymous inner class which implements the Runnable interface
                // - instatiate an instance of this inner class, with copies to all the data defined above
                // - submit it to the executor, store a reference to the Future object returned
                // - (sometime in the future(asap) it will start running the run method on a seperate work thread)
                Future future = executor.submit(new Runnable() {
                    public void run() {
                        // generate a writable image:
                        // if the date in the byte[] changes, the data in the BufferedImage also changes.
                        // because its the same data
                        Tuple<BufferedImage, byte[]> writableImage = generateWritableImage(tileSize);
                        
                        // render an image to the writableImage's byte[] based on all data provided above
                        boolean interrupted = renderMandelbrot(writableImage.item2, tileSize, rect, iters);
                        
                        // if we didn't get interrupted, assign the image ref we just rendered to the image array.
                        if (!interrupted)
                            image[index] = writableImage.item1;
                    }
                });
                
                // add the future reference to the list
                futureList.add(future);
            }
            
            
            // wait until all threads are done
            for (Future f : futureList) {
                try { 
                    // Future.get() is normally used to get the return value of a ExecutorService task
                    // but here we dont really have one, so it just causes it to wait until its done.
                    f.get();
                } catch(InterruptedException e) { // shouldn't happen in my app
                    System.err.println(e);
                } catch(ExecutionException e) { // shouldn't happen either
                    System.err.println(e);
                }
            }
            
            // if another thread has signalled abortion, abort!
            if(tryToAbortFlag)
                return;
            
            // stops other threads from starting rendering again, until this has been painted
            waitingForPaint = true;
            
            // send a message to the view on the UI thread, telling it to call paint() on us
            SwingUtilities.invokeLater(new Runnable() {
                public void run() {
                    // pass along the size and complexFrame we've used to render
                    asyncListener.readyForPainting(size, complexFrame);
                }
            });
        }
        
    }
    
    
    /**
     * Schedule an async rendering of the provided size, and complexFrame, and iterations.
     * 
     * @param size the size in pixels of the image generated
     * @param complexFrame the rectangle in Complex space to be rendered
     * @param iterations max number of iterations per pixel
     */
    public void scheduleAsyncRender(Dimension size,
                                    Rectangle2D.Double complexFrame,
                                    final int iterations) {
        
        if (synchronous)
            throw new IllegalStateException("Cant be called on an synchronous renderer");
        
        // if the timer exists, stop it
        if (timer != null)
            timer.stop();
        
        
        // copy reference types so that they dont get changed while in use by the async rendering system.
        final Dimension sizeCopy = (Dimension)size.clone();
        final Rectangle2D.Double frameCopy = (Rectangle2D.Double)complexFrame.clone();
        
        // declare/instatiate/assign a Thread subclass with a run method
        final Thread asyncControlThread = new Thread() {
            public void run() {
                startAsyncRender(sizeCopy, frameCopy, iterations);
            }
        };
        

        // wait 250 ms before starting rendering
        timer = new Timer(250, new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                // set the fired timerto null, so that we dont call stop on it
                // the next time someone calls scheduleAsyncRender(...)
                timer = null;
                
                // start asyncControlThread's run method on a seperate thread
                asyncControlThread.start();                
            }
        });
        
        // only fire the timer once
        timer.setRepeats(false);
        
        // start timer
        timer.start();
        
    }
    
    /** 
     * skipPaint - the view doesn't want our rendered data(probably because its out of date).
     * called by the view after its been notified that async rendering is done
     */
    public void skipPaint() {
        if (synchronous)
            throw new IllegalStateException("Cant be called on an synchronous renderer");
        
        synchronized (asyncRenderingInProgressLock) {
            waitingForPaint = false;  // done painting
            asyncRenderingInProgressLock.notifyAll(); // wake up other threads
        }
    }
    
    /** 
     * paint method used by the asynchronous renderer
     * called by the view after its been notified that async rendering is done
     *
     * @param g graphics context to render into
     */
    public void paint(Graphics g) {
        if (synchronous)
            throw new IllegalStateException("Cant be called on an synchronous renderer");
        
        if (!waitingForPaint)
            throw new IllegalStateException("Not done rendering, can't paint yet");
        
        
        // enter critical section
        synchronized (asyncRenderingInProgressLock) {
        
            // draw all images
            for (int i=0; i<threads; i++) {
                
                // draw image to the graphics context provided,
                // at the position prev. calculated and stored in tileFrame
                g.drawImage(image[i], 0, tileFrame[i].y, null);
            }
            
            waitingForPaint = false;  // done painting
            asyncRenderingInProgressLock.notifyAll(); // wake up other threads
        }
    }
    
    /**
     * Paint method for use by the synchronous renderer.
     * both renders and paints and image synchronously based on the parameters into the graphics context g
     *
     * @param g graphics context to render into
     * @param viewSize the size in pixels of the image generated
     * @param complexFrame the rectangle in Complex space to be rendered
     * @param iterations max number of iterations per pixel
     */
    public void paint(Graphics g, Dimension viewSize, Rectangle2D.Double complexFrame, int iterations) {
        if (!synchronous)
            throw new IllegalStateException("Cant be called on an asynchronous renderer");
        
        // save the current time (in ms)
        recordedStartTime = System.currentTimeMillis();
        
        // calculate the size of the image to render based on roughness
        Dimension imageSize = new Dimension(viewSize.width/roughness, viewSize.height/roughness);

        // (re)create databuffers/images etc, if the size of the window has changed.
        if (!viewSize.equals(lastSize) || roughness!=lastRoughness) {
            
            // generate a writable image
            Tuple<BufferedImage, byte[]> tuple = generateWritableImage(imageSize);
            
            // reuse the BufferedImage[] field(that the async renderer uses) to store just one image
            image[0] = tuple.item1;
            
            // store reference in the pixels field to the byte[], that we're about the render into
            pixels = tuple.item2;
        }
        
        // call the main rendering method, renders the image based on parameters into the field: pixels
        renderMandelbrot(pixels, imageSize, complexFrame, iterations);

        // scale image to match window size
        Image scaledImage = image[0].getScaledInstance(viewSize.width, viewSize.height, Image.SCALE_FAST);
        
        // draw the scaled image using the graphics context passed in.
        g.drawImage(scaledImage, 0, 0, null);
        
        
        // save for next time
        lastSize = viewSize;
        lastRoughness = roughness;
        
        // calculate the delta between the currentTime and the time we started rendering
        // in other words calculate the time it took to render
        long renderTime = System.currentTimeMillis() - recordedStartTime;
        
        // Adjust roughness according to the time it took to render
        if (renderTime > 50)
            roughness += renderTime/50; // if it took more than 50 ms, increase roughness
        if (renderTime < 30)
            roughness--;  // if it took less than 30ms, reduce roughness
            
        // limit roughness at 1 (pixel perfect)
        if (roughness < 1)
            roughness = 1;
        
    }
    /**
     * Generate a "linked"(both use the byte[] as actual storage) BufferedImage / byte[] pair.
     *
     * @param size the size of the image to generate
     * @return returns a 2-tuple of BufferedImage, and byte[]
     *         the BufferedImage is needed for drawing, and the byte[] is needed for changing the date
     */
    private Tuple<BufferedImage, byte[]> generateWritableImage(Dimension size) {
        
        int width = size.width;
        int height = size.height;
        
        // allocate a byte array with the capacity to hold an image
        // with the provided size (at 3 bytes per pixel)
        byte[] pix = new byte[width*height*3];
        
        // give a reference to the byte array to a container class, that is needed by the Raster below
        DataBufferByte buf = new DataBufferByte(pix, pix.length);
        
        // setup a sampleModel - a model needed by the raster to know how the pixels and colors components
        // are layed out, and width/height of the image, in the DataBufferByte
        SampleModel sampleModel = new PixelInterleavedSampleModel
                (DataBuffer.TYPE_BYTE, width, height, 3, 3*width, new int[]{0,1,2});
        
        WritableRaster raster = Raster.createWritableRaster(sampleModel, buf, null);
        
        // use a component based color model: RGB
        ColorModel cm = new ComponentColorModel(ColorSpace.getInstance(ColorSpace.CS_sRGB), 
                                                false, false, ComponentColorModel.OPAQUE, 
                                                DataBuffer.TYPE_BYTE);
        
        // create the actual BufferedImage object, needed for drawing by swing/awt                                        
        BufferedImage img = new BufferedImage(cm, raster, false, null);
                                                
        return new Tuple<BufferedImage, byte[]>(img, pix);
    }
    
    /**
     * The actual rendering method - render a mandelbrot image based on input data.
     * it cant be a static method because it needs access to the instance field: tryToAbortFlag
     * to be able to abort rendering at request.
     *
     * @param pix byte array representing the image: will render into this.
     * @param imageSize the size in pixels of the image to render into
     * @param complexFrame the rectangle in Complex space to be rendered
     * @param iterations max number of iterations per pixel
     * @return wether we were interupted or not
     */
    private boolean renderMandelbrot(byte[] pix,
                                     Dimension imageSize,
                                     Rectangle2D.Double complexFrame,
                                     int iterations) {
        
        int width = imageSize.width;
        int height = imageSize.height;
        int numberOfSpectrumColors = spectrum.length / 3;
        
        // calculate the difference between pixels and units in the complex space
        double reFactor = complexFrame.width / width;
        double imFactor = complexFrame.height / height;
        
        // allocate a complex number used by all iterations and pixels
        // this is the nice thing about the complex number being mutable
        Complex c = new Complex();
        
        // separate counter from the for-loop - index into the pixels array
        int pixIndex = 0;
        
        // generate some data in the pixels array for each pixel
        // starting top-left, and going row by row, until it reaches the bottom-right pixel
        // outer for-loop iterates per row
        for (int y=0; y<height; y++) {
            
            // set the "y" (imaginary) part of c to the position of the "pixel" along the im-axis
            c.im = complexFrame.y + y*imFactor;
            
            // each row, iterate through all pixels
            for (int x=0; x<width; x++) {
                
                // set the "x" (real) part of c to the position of the "pixel" along the re-axis
                c.re = complexFrame.x + x*reFactor;
                
                
                // if the View has initiated a new async rendering, and wants to abort the last one
                if (tryToAbortFlag) {
                    return true; // was interrupted
                }
                
                Complex z = new Complex(0,0);
                
                // need access to this from outside the for loop (after it has ended)
                int i = 0;
                
                // the main rendering loop, using the algoritm specified here:
                //      http://davis.wpi.edu/~matt/courses/fractals/mendel.html
                //
                for (; i<iterations; i++) {
                    
                    // take z to the power of two, and add c, store result in z
                    z.powerOfTwo().addWith(c);
                    
                    // use (z.squaredAbs() > 4) instead of (z.abs() > 2) for performance reasons.
                    if (z.squaredAbs() > 4) {
                        // this means this c value(cordinate in the complex space)
                        // is not part of the mandelbrot set ((ased on the current max iterations)
                        // so we break before reaching maximum number of iterations
                        break;
                    }
                }
                
                // if we iterated through to the max number of iterations
                if (i == iterations) {
                    
                    // this means at the current maximum iterations, we're guessing
                    // that the cordinate is part of the mandelbrot set
                    // thus: set the color to black
                    pix[pixIndex++] = (byte)0; // red
                    pix[pixIndex++] = (byte)0; // green
                    pix[pixIndex++] = (byte)0; // blue
                } else {
                    
                    // choose a color from the spectrum based on the number of iterations(i) it took to find out
                    // that we're not part of the mandelbrot set, (based on the current max iterations)
                    // pick an index into the spectrum, that is a multiplier of 3, and is within the spectrum
                    int index = (i % numberOfSpectrumColors) * 3;
                
                    pix[pixIndex++] = spectrum[index];   // red
                    pix[pixIndex++] = spectrum[index+1]; // green
                    pix[pixIndex++] = spectrum[index+2]; // blue
                }
            }
        }
        
        return false; // not interrupted, finished successfully
    }
}
