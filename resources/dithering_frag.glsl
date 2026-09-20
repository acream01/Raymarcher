#version 330 core 

out vec4 color;

//interpolated normal and light vector in camera space

//In from vertex shader
in vec3 fragNor;
in vec3 fragPos;
in vec3 lightDir;
in vec3 EPos;

uniform vec3 highcolor;
uniform vec3 lowcolor;
//Dithering Coloring

//Threshold map for 8x8 bayer matrix
//Dictates the color of a given pixel based on our projected grid
const int bayer64[64] = int[64](0,  32,  8,  40, 2, 34, 10, 42,
                                48, 16, 56, 25, 50, 18, 58, 26,
                                12, 44, 4, 36, 14, 46, 6, 38,
                                60, 28, 52, 20, 62, 30, 54, 22,
                                3, 35, 11, 43, 1, 33, 8, 41,
                                51, 19, 59, 27, 49, 17, 57, 25,
                                15, 47, 7, 39, 13, 45, 5, 37,
                                63, 31, 55, 23, 61, 29, 53, 21
                                );
uniform float ditherScaler;

void main()
{
    
	vec3 normal = normalize(fragNor);
	vec3 view = normalize(-EPos); 
	vec3 light = normalize(lightDir);
	 
    //Adjust diffuseScale AIDAN >:(
    float diffuse =  ditherScaler * max(dot(normal, light), 0);
	
    int column = int(mod(gl_FragCoord.x,8));
    int row= int(mod(gl_FragCoord.y,8));

    float threshold = float(bayer64[row * 8 + column]) / 64.0;


	if (diffuse > threshold){
      color = vec4(highcolor, 1.0);
    }
    else{
      color = vec4(lowcolor, 1.0);
    }
}
