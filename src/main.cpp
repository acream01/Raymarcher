/*
Aidan Ream Raymarcher Project
 */

#include <iostream>
#include <glad/glad.h>
#include <chrono>
#include <iostream>
#include <cstdlib>     

#include "GLSL.h"
#include "Program.h"
#include "Shape.h"
#include "MatrixStack.h"
#include "WindowManager.h"
#include "Texture.h"
#include "Bezier.h"
#include "Spline.h"

#define TINYOBJLOADER_IMPLEMENTATION
#include <tiny_obj_loader/tiny_obj_loader.h>

 // value_ptr for glm
#include <glm/gtc/type_ptr.hpp>
#include <glm/gtc/matrix_transform.hpp>

using namespace std;
using namespace glm;

class Application : public EventCallbacks
{

public:

	WindowManager* windowManager = nullptr;

	// Our shader program - use this one for Blinn-Phong
	std::shared_ptr<Program> fragProg;

	//Our shader program for textures
	std::shared_ptr<Program> texProg;

	std::shared_ptr<Program> ditherProg;

	GLuint emptyVAO;

	//the image to use as a texture
	shared_ptr<Texture> texture0;
	shared_ptr<Texture> texture1;

	
	//Pitch and Yaw Camera
	float pitchPhi;
	float yawTheta;

	vec3 w = vec3(0.0, 0.0, 0.0);
	vec3 eyePos = vec3(0.0, 0.0, 0.0);
	vec3 upDir = vec3(0, 1, 0);

	bool move_forward = false;
	bool move_backward = false;
	bool move_left = false;
	bool move_right = false;



	void keyCallback(GLFWwindow* window, int key, int scancode, int action, int mods)
	{
		if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
		{
			glfwSetWindowShouldClose(window, GL_TRUE);
		}
		//Moving Camera 
		//Forward
		if (key == GLFW_KEY_W && action == GLFW_PRESS) {
			move_forward = true;
		}
		else if (key == GLFW_KEY_W && action == GLFW_RELEASE) {
			move_forward = false;
		}
		//Back
		if (key == GLFW_KEY_S && action == GLFW_PRESS) {
			move_backward = true;
		}
		else if (key == GLFW_KEY_S && action == GLFW_RELEASE) {
			move_backward = false;
		}
		//Left
		if (key == GLFW_KEY_A && action == GLFW_PRESS) {
			move_left = true;
		}
		else if (key == GLFW_KEY_A && action == GLFW_RELEASE) {
			move_left = false;
		}
		//Right
		if (key == GLFW_KEY_D && action == GLFW_PRESS) {
			move_right = true;
		}
		else if (key == GLFW_KEY_D && action == GLFW_RELEASE) {
			move_right = false;
		}

		if (key == GLFW_KEY_Z && action == GLFW_PRESS) {
			glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		}
		if (key == GLFW_KEY_Z && action == GLFW_RELEASE) {
			glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
		}

	}

	void mouseCallback(GLFWwindow* window, int button, int action, int mods)
	{
		double posX, posY;

		if (action == GLFW_PRESS)
		{
			glfwGetCursorPos(window, &posX, &posY);
			cout << "Pos X " << posX << " Pos Y " << posY << endl;
		}
	}

	void resizeCallback(GLFWwindow* window, int width, int height)
	{
		glViewport(0, 0, width, height);
	}

	void scrollCallback(GLFWwindow* window, double deltaX, double deltaY) {
		int width, height;
		glfwGetWindowSize(window, &width, &height);
		if (!((pitchPhi >= 1.5 && deltaY > 0) || (pitchPhi <= -1.5 && deltaY < 0))) {
			pitchPhi += 100 * deltaY / height;
		}

		yawTheta += 100 * deltaX / width;

	}

	void init(const std::string& resourceDirectory)
	{
		GLSL::checkVersion();

		// Set background color.
		glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
		// Enable z-buffer test.
		glEnable(GL_DEPTH_TEST);

		//// Initialize the GLSL program that we will use for local shading
		fragProg = make_shared<Program>();
		fragProg->setVerbose(true);
		fragProg->setShaderNames(resourceDirectory + "/simple_vert.glsl", resourceDirectory + "/solid_frag.glsl");
		fragProg->init();
		fragProg->addUniform("solidColor");
	}

	void render(float frametime) {
		// Get current frame buffer size.
		int width, height;
		glfwGetFramebufferSize(windowManager->getHandle(), &width, &height);
		glViewport(0, 0, width, height);

		// Clear framebuffer
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		float aspect = width / (float)height;

		
		fragProg->bind();
		glUniform3f(fragProg->getUniform("solidColor"), 0.0, 0.7, 0.0); 
		glGenVertexArrays(1, &emptyVAO); glBindVertexArray(emptyVAO); 
		glDrawArrays(GL_TRIANGLES, 0, 3);
		fragProg->unbind();
		

	}
};

int main(int argc, char* argv[])
{
	// Where the resources are loaded from
	std::string resourceDir = "../resources";

	if (argc >= 2)
	{
		resourceDir = argv[1];
	}

	Application* application = new Application();

	// Your main will always include a similar set up to establish your window
	// and GL context, etc.

	WindowManager* windowManager = new WindowManager();
	windowManager->init(640, 480);
	windowManager->setEventCallbacks(application);
	application->windowManager = windowManager;

	application->init(resourceDir);
	
	auto lastTime = chrono::high_resolution_clock::now();

	// Loop until the user closes the window.
	while (!glfwWindowShouldClose(windowManager->getHandle()))
	{
		// save current time for next frame
		auto nextLastTime = chrono::high_resolution_clock::now();

		// get time since last frame
		float deltaTime =
			chrono::duration_cast<std::chrono::microseconds>(
				chrono::high_resolution_clock::now() - lastTime)
			.count();
		// convert microseconds (weird) to seconds (less weird)
		deltaTime *= 0.000001;

		// reset lastTime so that we can calculate the deltaTime
		// on the next frame
		lastTime = nextLastTime;
		// Render scene.
		application->render(deltaTime);

		// Swap front and back buffers.
		glfwSwapBuffers(windowManager->getHandle());
		// Poll for and process events.
		glfwPollEvents();
	}

	// Quit program.
	windowManager->shutdown();
	return 0;
}
