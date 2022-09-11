package haxe.root;

import java.awt.image.*;
import java.awt.event.*;
import java.awt.*;
import javax.swing.*;

// build with
//    javac ExtA.java 
//    jar cf l.jar *.class

class ExtA {  
    static JFrame jframe;
    static ImagePanel imgPanel;

    public static double f0(double a, double b) {  
        return a+b;
    }

    // create and initialize window for realtime visualization
    public static void createAndInitWindow() {
        jframe = new JFrame("frame");
  
        jframe.setSize(400, 400);

        imgPanel = new ImagePanel();
        jframe.add(imgPanel);
  
        jframe.show();
    }

    public static void update(String s) {
        BufferedImage img = new BufferedImage(400, 400, BufferedImage.TYPE_INT_ARGB);
        Graphics g = img.getGraphics();
        

        g.setColor(Color.BLACK);

        String[] lines = s.split("\n");

        for (String iLine: lines) {
            String[] tokens = iLine.split(" ");

            if (tokens[0].equals("b")) { // draw box
                int ax = Integer.parseInt(tokens[1]);
                int ay = Integer.parseInt(tokens[2]);
                int bx = Integer.parseInt(tokens[3]);
                int by = Integer.parseInt(tokens[4]);

                g.drawRect(ax, ay, bx-ax, by-ay);
            }
        }

        imgPanel.img = img; // update
        imgPanel.repaint(); // force redrawing
    }


    static class ImagePanel extends JPanel {
        public BufferedImage img;

        public ImagePanel() {
            img = new BufferedImage(400, 400, BufferedImage.TYPE_INT_ARGB);
        }

        @Override
        protected void paintComponent(Graphics g) {
            super.paintComponent(g);
            g.drawImage(img, 0, 0, null);
        }
    }
}
