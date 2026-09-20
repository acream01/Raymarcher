#version 330 core
uniform sampler2D Texture0;


in vec2 vTexCoord;
out vec4 Outcolor;
uniform int flip;

uniform vec3 highcolor;
uniform vec3 lowcolor;

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

void main() {
    vec4 texColor0 = texture(Texture0, vTexCoord);

    int column = int(mod(gl_FragCoord.x,8));
    int row= int(mod(gl_FragCoord.y,8));

    float threshold = float(bayer64[row * 8 + column]) / 64.0;

    

    if (length(texColor0) > threshold){
      Outcolor = vec4(highcolor, 1.0);
    }
    else{
        Outcolor = vec4(lowcolor, 1.0);
    }
  	//to set the out color as the texture color 
  	

    
  
  	//to set the outcolor as the texture coordinate (for debugging)
	//Outcolor = vec4(vTexCoord.s, vTexCoord.t, 0, 1);
}

