#version  330 core
out vec2 texcoords; // texcoords are in the normalized [0,1] range for the viewport-filling quad part of the triangle
void main() {
        vec2 vertices[3]=vec2[3](vec2(-1,-1), vec2(3,-1), vec2(-1, 3));
        gl_Position = vec4(vertices[gl_VertexID],0,1);
        texcoords = 0.5 * gl_Position.xy + vec2(0.5);
}
    /*Approach for setting up a full screan primative from derhass on Stack Overflow
        
        Triangle that extends beyond the corners of the window, with texture coordinates normalized
        [0,1] accross the viewport instead of a quad rendered with two triangles corners at the viewport edges.

        Major preformance advantage is not 1 less triangle cpu side or 1 less vertex for the vertex shader,
       instead it is many less fragment shader invocations along the particularly along the diagonal. 

        real-world GPUs use some different approaches like Guard-band clipping
        the rasterizer will produce fragments only for pixels inside the viewport
    */