#version 330 core 

out vec4 color;

uniform vec3 MatAmb;
uniform vec3 MatDif;
uniform vec3 MatSpec;
uniform float MatShine;


//interpolated normal and light vector in camera space
in vec3 fragNor;

//Sunlight Direction
in vec3 lightDir;

//Point light position and intensity
uniform vec3 LightPos; 
uniform vec3 LightInt; 

//position of the vertex in camera space
in vec3 EPos;



void main()
{
	//you will need to work with these for lighting
	vec3 normal = normalize(fragNor);
	vec3 light = normalize(lightDir);
	vec3 view = normalize(-EPos); 
	
	//Sun Light
	//Calculate V, the negative of EPos since our camera is at 0,0,0
	vec3 Halfway = (normalize(light + view));
	//Max so mininum is 0
	float dC = max(dot(normal, light), 0);
	float Ii = pow(max(dot(normal, Halfway), 0), MatShine);

	vec3 sunLight =  vec3(dC * MatDif + Ii * MatSpec);

	//PointLight
	vec3 pointLightDir = normalize(LightPos - EPos);
	float diffPoint = max(dot(normal, pointLightDir), 0.0);

	vec3 halfwayPoint = normalize(pointLightDir + view);
    float specPoint = pow(max(dot(normal, halfwayPoint), 0.0), MatShine);

    float distance = length(LightPos - EPos);
    float distanceFallOff = 1.0 / (1.0 + 0.09 * distance + 0.032 * (distance * distance)); // Quadratic falloff
	
	vec3 pointLighting = ((diffPoint * MatDif + specPoint * MatSpec) * LightInt) * distanceFallOff;
	
	

	color = vec4(MatAmb + sunLight + pointLighting, 1.0);
}
