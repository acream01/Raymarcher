#version 330 core
in vec2 texcoords;

out vec4 color;
uniform vec3 solidColor;

void main()
{
	
	vec3 col = solidColor;
	
	color = vec4(texcoords, 1.0, 1.0);
}
