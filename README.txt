Program 5
Aidan Ream

Final Project for CS471 Intro to Computer Graphics

The technology I chose to implement was a shader design based on the game "Return of the Obra Dinn".
The shading technique, called Dithering, was originally developed for print to trick the eyes into seeing
a multitude of shades while only using 2 colors. It achieves this by filling in dots depending on their given
brightness by referencing whats called a bayer matrix. It is a pattern that is checked to see whether the
threshold value of a given pixel reaches a certain level dictated by the pattern, and if it is to display that pixel,
otherwise display the low color. I implemented an 8x8 matrix for this project, that looks like this:

int[64](0,  32,  8,  40, 2, 34, 10, 42,
                                48, 16, 56, 25, 50, 18, 58, 26,
                                12, 44, 4, 36, 14, 46, 6, 38,
                                60, 28, 52, 20, 62, 30, 54, 22,
                                3, 35, 11, 43, 1, 33, 8, 41,
                                51, 19, 59, 27, 49, 17, 57, 25,
                                15, 47, 7, 39, 13, 45, 5, 37,
                                63, 31, 55, 23, 61, 29, 53, 21
                                );

This pattern creates a really interesting effect in a real time sinario, where normally the effect applies a smooth color
gradient to a limited color palate, but in real time the motion of the camera shows the pattern more clearly creating a 
strange retro styling that looks really interesting. 

An update from my first project, since the model for the world is still the same, is that I've added a spline that takes
you to Angelo's, a really great restaurant in Rome. Press 'g' to activate it! It resets itself as well.

Honestly, the scope of this project really fell short of what I was hoping to achieve. The shading works perfectly, but I attempted
to apply the same reference to textures with some strange behavior going unsolved before I had time to fix it. I tried to incorporate particles as well, but with the texturing not working it was not either. The Hydra mesh too was intended to be animated 
but I ran out of time. With that being said, the work I did developing this final project seriously depend every concept we covered throughout the quarter, and I feel like I have a really great grasp of how these programs work in and out.

Some controls for the program:
'g' Takes you on a tour through the city streets, from the center of the Piazza to the doorstep of Angelo's
'f' toggles flying mode and walking mode. You are in walking mode from the start
'WASD' used to move around, along with mouse scroll to change the direction you're looking
'o' & 'p' can be used to adjust the dithering scaler to change how much the pattern is applied to a model.

Compile with a c++ compiler and run
>mkdir build
>cd build
>cmake ..
>make
>./Project5

