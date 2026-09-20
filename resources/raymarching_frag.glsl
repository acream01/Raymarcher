#version 330 core
in vec2 texcoords;

out vec4 color;
uniform vec3 solidColor;
uniform vec2 iResolution;
uniform float iTime;

float distance_from_sphere(in vec3 p, in vec3 c, float r){
	// p is point in 3D
	// c is center of sphere
	// r is radius
	return length(p - c) - r;
}

float map_the_world(in vec3 p){
	float sphere_0 = distance_from_sphere(p, vec3(0.0), 1.0);
	//Opens up the possibility to have sdfs for multiple shapes

	return sphere_0;
}

//ro ray origin, rd ray direction
vec3 raymarch(in vec3 ro, in vec3 rd){
	float total_distance_traveled = 0.0;
	const int NUMBER_OF_STEPS = 32;
	const float MINIMUM_HIT_DISTANCE = 0.0001;
	const float MAXIMUM_TRACE_DISTANCE = 1000.0;

	for (int i = 0; i < NUMBER_OF_STEPS; i++){
		//Calculate current position along the ray
		vec3 current_position = ro + total_distance_traveled * rd;

		//Assume the sphere is centered at the origin with unit radius

		float distance_to_closest = map_the_world(current_position);

		if (distance_to_closest < MINIMUM_HIT_DISTANCE){
			//Hit! Return red 
			return vec3(1.0, 0.0, 0.0);
		}

		if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE){
			//Miss
			break;
		}

		//Accumulate the distance traveled so far
		total_distance_traveled += distance_to_closest;


	}
	
	//Return background if we missed
	return vec3(1.0 * ( 0.5 + sin(iTime)));
}

void main()
{
	float col_offset = sin(iTime) / 2;
	
	//Keeps image aspect ratio through window resize
	vec2 uv = (texcoords * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);

	vec3 camera_position = vec3(0.0, 0.0, -5.0);
	vec3 ro = camera_position;
	vec3 rd = vec3(uv, 1.0);

	//vec3 col = 0.5 + 0.5 * cos(iTime + uv.xyx + vec3(0, 2, 4));
	vec3 col = raymarch(ro, rd);

	color = vec4(col , 1.0);
	
}


//Made following MichaelWalczyk tutorial intro to ray marching