#version 330 core
in vec2 texcoords;

out vec4 color;
uniform vec3 solidColor;
uniform float iTime;

void main()
{
	float col_offset = sin(iTime) / 2;
	
	vec2 uv = texcoords;
	vec3 col = 0.5 + 0.5 * cos(iTime + uv.xyx + vec3(0, 2, 4));
	
	color = vec4(col, 1.0);
}

/*
// Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));

    // Output to screen
*/