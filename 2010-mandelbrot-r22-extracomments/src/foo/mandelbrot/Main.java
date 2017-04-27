package foo.mandelbrot;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.awt.event.*;

public class Main {

    public static void main(String[] args) {
        
        // schedule for invoking once the swing mainloop(event dispatch thread) starts.
        // all calls that interact with swing must be done on the swing event dispatch thread
        // source: http://www.javaranch.com/journal/200410/JavaDesigns-SwingMultithreading.html
        
        SwingUtilities.invokeLater(new Runnable() {
            public void run() {
                
                // the view and the panel needs to be final so 
                // that they can be accessed by the anonymous inner class below
                
                // the reason they decided to to this im guessing is probably
                // because local(stack based) variables (both primitive and references to objects)
                // gets copied when declaring a method that accesses them from within an anonymous inner class.
                
                // if it weren't necessary to declare them final, when you changed the copied variable from the
                // inner class method, programmers would think it also changed the original variable.
                // but it cant: because those variables probably doesn't exist anymore.
                // (with "variable" for reference types i only mean the actual reference, 
                // not the object they reference)
                final MandelView view = new MandelView();
                
                // pass along the view to the sidepanel so that it can control it
                final SidePanel panel = new SidePanel(view);
                
                // but a border around the panel by 5 pixels on all sides
                panel.setBorder(new EmptyBorder(5,5,5,5));
                
                
                
                // setup a JFrame(a window), titled Mandelbrot
                // using "double brace initialization" because it makes the code
                // so much easier to read imo (some consider it an abuse)
                
                // i'll describe what actually happens with "double brace initialization" once here
                // but will use it in other places in the project without explanation:
                
                // - It starts by declaring an anonymous inner class (subclass of JFrame in this case)
                // - and declaring an unamed constructor(instance initializer blocker) in the inner class
                // - then it allocates an instance of this class causing the JFrame constructor to be called with
                //   parameter "Mandelbrot" (the title of the window)
                // - then the just declared instance initializer block code runs, and further sets the object up
                // - then it gets assigned to the local JFrame reference variable called: frame
                
                JFrame frame = new JFrame("Mandelbrot") {{
                    setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
                    add(view, BorderLayout.CENTER);
                    add(panel, BorderLayout.LINE_END);
                    setSize(1024, 768);
                    setLocationRelativeTo(null);
                }};
                
                // tell the window to show itself
                frame.setVisible(true);
            }
        });
        
        // at this point the original main thread is finished
        // i guess you could say the swing mainloop has taken over as main thread in a way.
    }
}
