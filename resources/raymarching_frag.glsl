#version 330 core
in vec2 texcoords;

out vec4 color;
uniform vec3 solidColor;
uniform vec2 iResolution;
uniform int maxDepth;
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


float repeated(vec3 p) {
	p.x = p.x - round(p.x);
	return 0.0; //sdf;
}

const float PI = 3.14159265;
const float TWO_PI  = 6.28318531;
const float A = 1.0;
const float B = 0.1;
const float THETA_MIN = -20.0 * PI;
const float THETA_MAX = 0.0;
const float DELTA = 0.533;
const int   N_CHILDREN =  139;//126;   // (THETA_MAX - THETA_MIN) / DELTA
int   MAX_DEPTH   = maxDepth; //3
const float CONE_H      =  2.0;
const float CHILD_SCALE =  0.19;

vec3 childCenter(int k) {
    float theta = THETA_MIN + float(k) * DELTA;
    float e = exp(B * theta);
    return vec3(A * e * cos(theta), A * e * sin(theta), -e);
}

int nearestChildIndex(vec3 p) {
    float rho = max(length(p.xy), 1e-6);   // avoid log(0) on the z-axis
    float phi = atan(p.y, p.x);            // (-π, π]

    float thetaR = log(rho / A) / B;       // θ where spiral radius == rho
    float m      = round((thetaR - phi) / TWO_PI);
    float theta  = phi + TWO_PI * m;       // same angle as p, nearest radius

    int k = int(round((theta - THETA_MIN) / DELTA));
    return clamp(k, 0, N_CHILDREN - 1);
}

void childFrame(int k, out float s, out mat3 Rinv, out vec3 c) {
    float theta = THETA_MIN + float(k) * DELTA;
    float e = exp(B * theta);
    s = CHILD_SCALE * e;
    c = childCenter(k);

    float ct = cos(theta), st = sin(theta); //Cos theta sin theta
    float ca = 0.70710678;
	float sa = 0.70710678;          // 45 degrees cos angle, sine angle
    mat3 Rz = mat3( ct, st, 0.0,  -st, ct, 0.0,  0.0, 0.0, 1.0);
    mat3 Ry = mat3( ca, 0.0, -sa,  0.0, 1.0, 0.0,  sa, 0.0, ca);
    Rinv = transpose(Rz * Ry);
}

float sdCone( vec3 p, vec2 c, float h )
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
  vec2 q = h*vec2(c.x/c.y,-1.0);
    
  vec2 w = vec2( length(p.xz), p.y );
  vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
  return sqrt(d)*sign(s);
}

float sdConeZ(vec3 p) {
	//Cone facing down the z direction
    return sdCone(vec3(p.x, p.z, p.y), vec2(1.0), CONE_H);
}


float sdRommanesco(vec3 p) {
	float scale = 1.0;
	float d = 1e9;
	for (int level = 0; level < MAX_DEPTH; level++){
		d = min(d, scale * sdConeZ(p));
		int k = nearestChildIndex(p); //from angle + log radius
		 // inverse of S1*S2*R*T for child k (translate, rotate back, unscale)
		float s; //Scale
		mat3 Rinv; //Rotation inverse
		vec3 c; 
		childFrame(k, s, Rinv, c);

		p = Rinv * (p - c) / s + vec3(0.0, 0.0, -CONE_H);
		scale *= s;
	}

	return d;
}


float sdConeInf( vec3 p, vec2 c )
{
	//Infinite Cone
    // c is the sin/cos of the angle
    vec2 q = vec2( length(p.xz), -p.y );
    float d = length(q-c*max(dot(q,c), 0.0));
    return d * ((q.x*c.y-q.y*c.x<0.0)?-1.0:1.0);
}

/*
float map_the_world(in vec3 p){

	vec3 q = p - vec3(0.0, 0.0, 1.0); //Position
	float displacement = sin(5.0 * p.x) * sin(5.0 * p.y) * sin(5.0 * p.z) * 0.25;
	//float sphere_0 = sdSphere(p, vec3(0.0, 0.0, sin(iTime) * 0.25), 2.0);
	//float sphere_1 = sdSphere(p, vec3( sin(iTime) * 3.0, cos(iTime) * 3.0, 0.0), 2.0);
	//Opens up the possibility to have sdfs for multiple shapes
	//float box_1 = sdBox(q, vec3(1.0, 0.5, 1.0));
	float cone_01 = sdCone(q, vec2(0.7, 1.0), 3.0);
	//float cone_01 = sdConeInf(p, vec2(1.0));
	
	//q = p - vec3(1.0);
	//float box_2 = sdBox(q, vec3(1.0, 0.5, 1.0));
	displacement *= cos(iTime);

	//return opSmoothUnion(sphere_0, sphere_1, 0.3) + displacement;
	//return opUnion(box_1, box_2) + displacement;
	//return opSmoothUnion(sphere_0, sphere_1, 0.25) + displacement;
	return cone_01;
}
*/

	float map_the_world(in vec3 p){
	//For romanessco
	float c = cos(2.2);
	float s = sin(2.2);
	mat3 rx =  mat3(1, 0, 0,    0, c, s,   0, -s, c);
	vec3 q = rx * p + vec3(0.0, 0.0, -1.0); //Rotate around shape center

	//float displacement = sin(5.0 * p.x) * sin(5.0 * p.y) * sin(5.0 * p.z) * 0.01;
	//displacement *= cos(iTime);

	return 0.25 * sdRommanesco(q);
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
			vec3 light_position = vec3(2.0, 3.0, -3.0);

			vec3 direction_to_light = normalize(light_position - current_position);

			float diffuse_intensity = max(0.0, dot(normal, direction_to_light));

			//ambient occlusion based on steps we take to reach a part of the sdf
			float ambient_occlusion = 10.0 / i;

			return mat * diffuse_intensity * ambient_occlusion;
			//return mat * ambient_occlusion;
			//return mat * diffuse_intensity;// * 1/ambient_occlusion;
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
	//return vec3(0.5 + 0.5 * cos(iTime + texcoords.xyx + vec3(0, 2, 4)));
	return vec3(0.67);
}

void main()
{
	float col_offset = sin(iTime) / 2;
	
	//Keeps image aspect ratio through window resize
	vec2 uv = (texcoords * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);

	vec3 camera_position = vec3(0.0, -0.7, -3.1);
	vec3 ro = camera_position;
	vec3 rd = normalize(vec3(uv, 1.0));

	//vec3 mat = vec3(1.0, sin(iTime) * 0.5 + 0.5, cos(iTime) * 0.5 + 0.5);
	vec3 mat = vec3(0.0, 0.9, 0.2);
	//vec3 col = 0.5 + 0.5 * cos(iTime + uv.xyx + vec3(0, 2, 4));
	vec3 col = raymarch(ro, rd, mat);

	 // gamma
     col =  pow( col,  vec3(0.4545) );

	//Vignetting
	vec2 q = texcoords;
	col *= pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.17 );

	color = vec4(col , 1.0);
	
}


//Made following MichaelWalczyk tutorial intro to ray marching