package foo.mandelbrot;

import java.util.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.event.*;
import java.awt.*;
import java.awt.event.*;



/**
 * SidePanel is a subclass of JPanel, it provides the UI needed to control a MandelView.
 */
public class SidePanel extends JPanel implements MandelView.Listener, ChangeListener, ItemListener {
    /**
     * Reference to the MandelView its controlling.
     */
    private MandelView  mandelView;
    
    /**
     * The last value of the number of iterations. Stored so that we dont rerender if nothing has changed.
     * Hardcoded to 256 because thats the initial number of iterations
     * (fix: should not really be hardcoded here, maybe it would be passed from the constructor instead)
     */
    private int         lastValue = 256;
    
    
    // references to the UI widgets/components this Panel uses(cant be bothered with javadoc for these)
    private JLabel      renderTimeLabel;
    private JLabel      iterationsLabel;
    private JSlider     iterationsSlider;
    private JCheckBox   threadedCheckBox;
    
    /**
     * SidePanel constructor.
     *
     * @param mandelView take control(access setters) of this MandelView instance.
     */
    public SidePanel(MandelView mandelView) {
        
        // set the layout mode of the SidePanel to BoyLayout, along the YAXIS(top to bottom)
        // which means components added to the SidePanel will be placed from the top to the bottom
        setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
        
        // save reference to the mandelView we intend to control
        this.mandelView = mandelView;
        
        // give the mandelView a reference to ourself,
        // that it can use to notify us about stuff(in this case how long it took to render)
        // this only works because we implement the interface MandelView.Listener
        // or we would get a compile time error
        mandelView.setListener(this);
        

        // Create checkbox named "Multithreaded" which is checked by default(second param: true)
        // again using "double brace initialization" described in detail in Main.java
        threadedCheckBox = new JCheckBox("Multithreaded", true) {{
            
            // if we're only running on one CPU
            if (Runtime.getRuntime().availableProcessors() == 1) {
                // make this checkbox gray (disabled)
                setEnabled(false);
                setSelected(false);
            }
            
            // give the checkbox a reference to the SidePanel instance
            // we can use this syntax(SidePanel.this) inside an anonymous inner class,
            // to reach the enclosing class instance 
            addItemListener(SidePanel.this);
            
            // center the component
            setAlignmentX(Component.CENTER_ALIGNMENT);
        }};
        
        // Create a vertical slider, with the range 0..10 and a start value of 8
        // again using "double brace initialization" described in detail in Main.java
        iterationsSlider = new JSlider(JSlider.VERTICAL, 0, 10, 8) {{
            
            // center this component as well
            setAlignmentX(Component.CENTER_ALIGNMENT);
            
            // doesn't need explanation
            setPaintTicks(true);
            setPaintLabels(true);
            setMajorTickSpacing(1);
            setSnapToTicks(true);
            
            // give the slider a reference to the SidePanel(enclosing class)
            addChangeListener(SidePanel.this);
            
            // set the sliders LableTable to a HashTable(dictionary/map) of Interger and JLabel 
            // that describes a mapping between i(0..10) and a JLabel with the label:
            //     2 to the power of i(0..10)            
            setLabelTable(new Hashtable<Integer, JLabel>() {{
                for (int i=0; i<=10; i++) {
                    int aPowerOfTwo = (int)Math.pow(2,i);
                    put(i, new JLabel(Integer.toString(aPowerOfTwo)));
                }                
            }});
        }};
        
        // create an JLabel showing the number of iterations, make it centered
        iterationsLabel = new JLabel("Max number of iterations:");
        iterationsLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
        
        // create a JLabel showing the render time, also make it centered
        renderTimeLabel = new JLabel("Render time:   ms");
        renderTimeLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
        
        
        // add all widgets/components to the SidePanel in the order we want them to be drawn
        // top to bottom (Y_AXIS)
        add(threadedCheckBox);
        add(iterationsLabel);
        add(iterationsSlider);
        add(renderTimeLabel);
    }
    
    
    
    /**
     * ChangeListener override - events coming from the JSlider.
     *
     * @param e an instance of ChangeEvent, providing information about the event.
     */
    public void stateChanged(ChangeEvent e) {
        // since we're "faking" a logarithmic slider, we need to take the value of the slider(0..10)
        // and take 2 to the power of it to get the value that we put on the Slider labels above.
        int value = (int) (Math.pow(2, iterationsSlider.getValue()));
        
        // if the value we got is the same as the value we got last time we changes iterations:
        // return to not cause any unnecessay rerender of the image.
        if (value == lastValue)
            return;
        
        // pass along the new max number of iterations to the MandelView
        mandelView.setIterations(value);
        
        // remember the value of value until next time this method is called
        // using an instance variable in the SidePanel
        lastValue = value;
    }
    
    /**
     * ItemListener override - events coming from the JCheckBox.
     *
     * @param e an instance of ItemEvent, providing information about the event.
     */
    public void itemStateChanged(ItemEvent e) {
        
        // use a MandelView setter to change the state to the state of the checkbox
        mandelView.setThreaded(threadedCheckBox.isSelected());
    }
    
    
    /**
     * MandelView.Listener override - events coming from the MandelView.
     *
     * @param renderTimeMillis the time it took to render the scene using the async renderer.
     */
    public void renderComplete(long renderTimeMillis) {
        
        // update the renderTimeLabel with the time it took to render
        renderTimeLabel.setText(String.format("Render time: %d ms", renderTimeMillis));
    }
}