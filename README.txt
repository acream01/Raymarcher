Raymarcher
Aidan Ream

Raymarcher made following Michael Walczyk tutorial intro to ray marching
 
Program uses openGl to render a single triangle primitive covering the screen with texture coordinates normalized along screen space.
Almost all of the magic is happening in the fragment shader, where Signed distance funcitons are being used to create 3D worlds out of math.
Shoutout Inigo Quilez, Michael Walczyk and many many more people who have documented their adventures in raymarching.

Initial openGL basecode taken from Dr Zoe Wood and modified by Aidan Ream for Intro to Computer Graphics 471

Build and compile using Cmake, then run from the /out directory. 