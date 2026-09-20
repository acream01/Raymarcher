#version 330 core
in vec2 texcoords;

out vec4 color;
uniform vec3 solidColor;
uniform vec2 iResolution;
uniform float iTime;


float opUnion( float a, float b )
{
    return min(a,b);
}
float opSubtraction( float a, float b )
{
    return max(-a,b);
}
float opIntersection( float a, float b )
{
    return max(a,b);
}
float opXor( float a, float b )
{
    return max(min(a,b),-max(a,b));
}
float opSmoothUnion( float a, float b, float k )
{
    k *= 4.0;
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}
float opSmoothSubtraction( float a, float b, float k )
{
    return -opSmoothUnion(a,-b,k);

    // k *= 4.0;
    // float h = max(k-abs(-a-b),0.0);
    // return max(-a, b) + h*h*0.25/k;
}
float opSmoothIntersection( float a, float b, float k )
{
    return -opSmoothUnion(-a,-b,k);

    // k *= 4.0;
    // float h = max(k-abs(a-b),0.0);
    // return max(a, b) + h*h*0.25/k;
}

float sdSphere(in vec3 p, in vec3 c, float r){
	// p is point in 3D
	// c is center of sphere
	// r is radius
	return length(p - c) - r;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float map_the_world(in vec3 p){
	
	vec3 q = p - vec3(-1.0); //Position
	float displacement = sin(5.0 * p.x) * sin(5.0 * p.y) * sin(5.0 * p.z) * 0.25;
	//float sphere_0 = sdSphere(p, vec3(0.0, 0.0, sin(iTime) * 0.25), 2.0);
	//float sphere_1 = sdSphere(p, vec3( sin(iTime) * 3.0, cos(iTime) * 3.0, 0.0), 2.0);
	//Opens up the possibility to have sdfs for multiple shapes
	float box_1 = sdBox(q, vec3(1.0, 0.5, 1.0));

	q = p - vec3(1.0);
	float box_2 = sdBox(q, vec3(1.0, 0.5, 1.0));
	displacement *= cos(iTime);

	//return opSmoothUnion(sphere_0, sphere_1, 0.3) + displacement;
	return opUnion(box_1, box_2) + displacement;
}

vec3 calculate_normal(in vec3 p){
	//Ccalculating the normal of an arbitrary shape by finding
	//how the sdf distance changes on a small distance change ds

	const vec3 small_step = vec3(0.001, 0.0, 0.0);

    float gradient_x = map_the_world(p + small_step.xyy) - map_the_world(p - small_step.xyy);
    float gradient_y = map_the_world(p + small_step.yxy) - map_the_world(p - small_step.yxy);
    float gradient_z = map_the_world(p + small_step.yyx) - map_the_world(p - small_step.yyx);

	vec3 normal = vec3(gradient_x, gradient_y, gradient_z);

	return normalize(normal);
}

//ro ray origin, rd ray direction
vec3 raymarch(in vec3 ro, in vec3 rd, in vec3 mat){
	float total_distance_traveled = 0.0;
	const int NUMBER_OF_STEPS = 128;
	const float MINIMUM_HIT_DISTANCE = 0.005;
	const float MAXIMUM_TRACE_DISTANCE = 1000.0;

	for (int i = 0; i < NUMBER_OF_STEPS; i++){
		//Calculate current position along the ray
		vec3 current_position = ro + total_distance_traveled * rd;

		//Assume the sphere is centered at the origin with unit radius

		float distance_to_closest = map_the_world(current_position);

		if (distance_to_closest < MINIMUM_HIT_DISTANCE){
			//Hit! Return red 
			vec3 normal = calculate_normal(current_position);

			//temporary hardcoded light for testing
			vec3 light_position = vec3(2.0, -5.0, 3.0);

			vec3 direction_to_light = normalize(current_position - light_position);

			float diffuse_intensity = max(0.0, dot(normal, direction_to_light));


			return mat * diffuse_intensity;
		}

		if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE){
			//Miss
			break;
		}

		//Accumulate the distance traveled so far
		total_distance_traveled += distance_to_closest;


	}
	
	//Return background if we missed
	//return vec3(1.0 * ( 0.5 + sin(iTime)));
	return vec3(0.5 + 0.5 * cos(iTime + texcoords.xyx + vec3(0, 2, 4)));
	//return vec3(0.0);
}

void main()
{
	float col_offset = sin(iTime) / 2;
	
	//Keeps image aspect ratio through window resize
	vec2 uv = (texcoords * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);

	vec3 camera_position = vec3(0.0, 0.0, -5.0);
	vec3 ro = camera_position;
	vec3 rd = vec3(uv, 1.0);

	vec3 mat = vec3(1.0, sin(iTime) * 0.5 + 0.5, cos(iTime) * 0.5 + 0.5);
	//vec3 mat = vec3(texcoords.x, 0.0, 0.0);
	//vec3 col = 0.5 + 0.5 * cos(iTime + uv.xyx + vec3(0, 2, 4));
	vec3 col = raymarch(ro, rd, mat);

	color = vec4(col , 1.0);
	
}


//Made following MichaelWalczyk tutorial intro to ray marching