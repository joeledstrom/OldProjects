
package foo.mandelbrot;
 
import foo.mandelbrot.util.*; 
import javax.swing.*;
import javax.swing.event.*;
import java.awt.*;
import java.awt.geom.*;
import java.awt.event.*;


/** 
 * MandelView is a subclass of JPanel, that can draw a Mandelbrot rendering.
 * It is resposible for handling mouseEvents (dragging, doubleclicking, wheel)
 * and drawing a Mandelbrot image using the Renderer class
 * It also has a couple of setters for changing state(in this app these are called by the SidePanel)
 */
public class MandelView extends JPanel 
        implements MouseInputListener, MouseWheelListener, Renderer.Listener {
            
    private Point2D.Double      complexCenterPosition = new Point2D.Double(-0.5, 0.0);
    private double              complexWidth = 3.0;
    private Dimension           sizeToBePainted;
    private Rectangle2D.Double  complexFrameToBePainted;
    private Point               lastMouseCoords;
    private Renderer            asyncRenderer;
    private Renderer            roughRenderer;
    private int                 iterations;
    private boolean             threaded;
    private Listener            listener;
    private boolean             highResPaintMode = false;
    private long                recordedStartTime;
    
    
    /**
     * MandelView.Listener interface has to be implemented by users of this class. 
     */
    public interface Listener {
        
        // get's called by the MandelView, when a highres render is complete
        // to notify users of this class of when it was done, and how long it took. 
        void renderComplete(long renderTimeMillis);
    }

    /**
     * Default constructor, just calls the designated constructor with some default values.
     */
    public MandelView() {
        this(256, true);
    }
    
    /**
     * Designated constructor.
     *
     * @param iterations initial maximum number of iterations to use in the mandelbrot rendering (per pixel)
     * @param threaded whether we're initially in threaded mode or not 
     */
    public MandelView(int iterations, boolean threaded) {
        
        // save options in instance fields
        this.iterations = iterations;
        this.threaded = threaded;
        
        // add ourself as listener to different types of mouse events for this component
        // generated by the swing API
        addMouseListener(this);
        addMouseWheelListener(this);
        addMouseMotionListener(this);
        
        // create the needed renders, the roughRenderer for painting preview images while moving
        // and an async multithreaded renderer for rendering highres images
        asyncRenderer = Renderer.createAsyncRenderer(this.threaded, this);
        roughRenderer = Renderer.createSyncFastRenderer();
    }
    
    /**
     * Setter for the field: listener.
     */
    public void setListener(Listener listener) {
        this.listener = listener;
    }
    
    /**
     * Setter for the field: threaded.
     */
    public void setThreaded(boolean threaded) {
        this.threaded = threaded;
        
        // recreate the async renderer, with the new state of this.threaded
        asyncRenderer = Renderer.createAsyncRenderer(this.threaded, this);
        
        // trigger a repaint
        repaintAll();
    }
    
    /**
     * Setter for the field: iterations.
     */
    public void setIterations(int iterations) {
        this.iterations = iterations;
        
        // trigger a repaint, so that we get to see how the
        // image looks after changing the number of iterations
        repaintAll();
    }
    
    
    /**
     * Called by the swing API when our component has recieved a mousePress event
     * (mouse button down without releasing it yet)
     *
     * @param e a MouseEvent containing some information about the event
     */
    public void mousePressed(MouseEvent e) {
        
        // save the mouse coords where the drag begun
        lastMouseCoords = e.getPoint();
    }
    /**
     * Called by the swing API when our component has recieved a mouseDragged event
     * (this means the mouse has been moved while being in "mousePressed state")
     *
     * @param e a MouseEvent containing some information about the event
     */
    public void mouseDragged(MouseEvent e) {
        
        // calculate how much the mouse has moved since the last call to this method
        // or in the case of the first time: since mousePressed(...) was called
        int deltaX = e.getPoint().x - lastMouseCoords.x;        
        int deltaY = e.getPoint().y - lastMouseCoords.y;
        
        
        // calculate pixel to complexSpace conversion factor
        double pixelToComplexFactor = complexWidth / getSize().width;
        
        
        // move the coords of the center position in complex space, by the deltas times the conversion factor 
        complexCenterPosition.x -= deltaX*pixelToComplexFactor;
        complexCenterPosition.y -= deltaY*pixelToComplexFactor;
        
        
        // save the mouse coords until next time we get called
        lastMouseCoords = e.getPoint();
        
        // trigger repaint - or else we wouldnt see any movement
        repaintAll();
    }
    
    /**
     * Called by the swing API when our component has recieved a mouseclick (or double/triple/etc click)
     *
     * @param e a MouseEvent containing some information about the event
     */
    public void mouseClicked(MouseEvent e) {
        
        // if doubleclick
        if (e.getClickCount() == 2) {
            
            // calculate the size of the view that its possible to draw in (minus insets)
            int width =  getSize().width - getInsets().left - getInsets().right;
            int height =  getSize().height - getInsets().top - getInsets().bottom;
            
            // calculate how many pixels from the center the doubleclick happened
            int distanceFromCenterX = e.getPoint().x - width/2;        
            int distanceFromCenterY = e.getPoint().y - height/2;

            // calculate pixel to complexSpace conversion factor
            double pixelToComplexFactor = complexWidth / getSize().width;

            // move the doubleclicked position to the center
            complexCenterPosition.x += distanceFromCenterX*pixelToComplexFactor;
            complexCenterPosition.y += distanceFromCenterY*pixelToComplexFactor;
            
            // zoom in 50%
            complexWidth -= complexWidth*0.5; 
            
            // safety check, preventing it from reaching 0
            if(complexWidth <= 0.0) complexWidth = 0.000000000001;
            
            repaintAll();
        } 
    }
    
    
    /**
     * Called by the swing API when the mouse wheel has been used above or component
     *
     * @param e a MouseWheelEvent containing some information about the event
     */
    public void mouseWheelMoved(MouseWheelEvent e) {
        
         // zoom by 10%(0.1) per mousewheel tick
        complexWidth += e.getWheelRotation()*complexWidth*0.1;
        
        // checks so that we dont go out of range(i had it go negative once, flipping the image along the y axis)
        if(complexWidth > 20) complexWidth = 20;
        if(complexWidth <= 0.0) complexWidth = 0.000000000001;
        
        // trigger repaint
        repaintAll();
    }
   
    
    /**
     * Called by the swing API when it's gotten notified that the component needs repainting
     *
     * @param g graphics context to render into
     */
    public void paintComponent(Graphics g) {
        
        Tuple<Dimension, Rectangle2D.Double> frameSizes = calculateFrameSizes();
        
        if (highResPaintMode) {
            
            // restore flag
            highResPaintMode = false;
            
            // check (again) if the data still is relevant (not out of date)
            // if for example the complexFrame's doesn't match:
            //     it means that the user has either zoomed or panned
            if (sizeToBePainted.equals(frameSizes.item1) &&
                complexFrameToBePainted.equals(frameSizes.item2)) {
                
                // paint data
                asyncRenderer.paint(g);
            
                // calculate the time it took to render
                long time = System.currentTimeMillis() - recordedStartTime;
                
                // notify the View listener of the time it took to render
                listener.renderComplete(time);
                
                // we're done and we dont want to do any rough rendering
                // or rescheduling of highres rendering
                return;
            }
            
            // out of date, no point in painting the rendered data
            asyncRenderer.skipPaint(); 
        }
        
        
        // render and paint rough preview frame
        roughRenderer.paint(g, frameSizes.item1, frameSizes.item2, iterations);
        
        
        // schedule high resolution rendering            
        asyncRenderer.scheduleAsyncRender(frameSizes.item1, frameSizes.item2, iterations);
        
        recordedStartTime = System.currentTimeMillis();
    }
    
    /**
     * Renderer.Listener override - used by asyncRenderer to notify the View when its done rendering.
     * call skipPaint() if we're going to ignore the data since its out of date
     *
     * @param size size of the image that has been rendered
     * @param complexFrame position and size of the frame of Complex Space rendered
     */
    public void readyForPainting(Dimension size, Rectangle2D.Double complexFrame) {
        
        Tuple<Dimension, Rectangle2D.Double> frameSizes = calculateFrameSizes();
        
        // remember these until paintComponent(...) gets called
        sizeToBePainted = size;
        complexFrameToBePainted = complexFrame;
        
        
        // check if the data still is relevant (not out of date)
        // if for example the complexFrame's doesn't match:
        //     it means that the user has either zoomed or panned
        if (sizeToBePainted.equals(frameSizes.item1) &&
            complexFrameToBePainted.equals(frameSizes.item2)) {
            
            // activate highResPaintMode and ask for a repaint
            highResPaintMode = true;
            repaintAll();
        } else {
            
            // the data is out of date, skip painting it
            asyncRenderer.skipPaint();
        }
            
    }
    
    /**
     * convenience method for notifying swing that we want to repaint the whole view.
     */
    private void repaintAll() {
        repaint(0,0,0, getSize().width, getSize().height);
    }
    
    
    /**
     * Calculate drawable image size and the current(based on where the user has moved) complexFrame
     *
     * @return return image size, and the corresponding complexFrame
     */
    private Tuple<Dimension, Rectangle2D.Double> calculateFrameSizes() {
        // calulate the drawable pixel size of the view, based on viewsize, and insets
        int width =  getSize().width - getInsets().left - getInsets().right;
        int height =  getSize().height - getInsets().top - getInsets().bottom;
        Dimension size = new Dimension(width, height);
        
        // calculate the complex frame based on center position and width
        Rectangle2D.Double complexFrame = new Rectangle2D.Double();
        complexFrame.width = complexWidth;
        complexFrame.height = (double)height/width*complexWidth; // preserve aspect-ratio
        complexFrame.x = complexCenterPosition.x - complexFrame.width/2;
        complexFrame.y = complexCenterPosition.y - complexFrame.height/2;
        
        return new Tuple<Dimension, Rectangle2D.Double>(size, complexFrame);
    }
    
    // unused overrides
    public void mouseExited(MouseEvent e) {}
    public void mouseEntered(MouseEvent e) {}
    public void mouseReleased(MouseEvent e) {}
    public void mouseMoved(MouseEvent e) {}
}