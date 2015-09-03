# On drawing layers over characters

I coded up a few samples to find the best way to layer over moving characters. 

Goal: Draw a character sprite partially behind a wall.
    
Methods tried:

1. Stencil Image (Fails)
This mask image has transparency, with filled areas where the wall should be drawn. Drawing this image as the stencil has no effect, as the transparent areas of the mask still trigger the stencil to draw where it should not.

2. Stencil Poly (Fails)
We loop through the mask pixel data and build a list of polygon vertices where the mask has colours, and draw the poly out as the stencil. The concave/convex nature of the pixels bamboozles the polygon.

3. Stencil Loop (Works at great CPU cost)
We loop through the mask pixel data, and where the pixel has a colour, we draw a pixel out from the stencil. This method works, but the CPU usage shoots up way too much for my comfort. Up to ~60%.

4. Image overlay (Works)
We load a copy of the background with the layer cut out. We draw this over the normal background and character.
The drawback to this method is it complicates our workflow by having to duplicate backgrounds images as layers.

5. Automatic image overlay (Works)
We copy the background image, loop over the mask pixel data, and where the mask pixel has a color we preserve the pixel in the layer copy, all other pixels are made transparent. This is a once-off process. During screen updates, draw the layer as an overlay.
This uses method #4 but instead of loading a prefabricated overlay, we create the overlay from the original background and mask.
This method works best. It keeps our workflow simple without the CPU overhead.
