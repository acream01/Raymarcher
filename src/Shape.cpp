
#include "Shape.h"
#include <iostream>
#include <cassert>

#include "GLSL.h"
#include "Program.h"

using namespace std;


// copy the data from the shape to this object
void Shape::createShape(tinyobj::shape_t& shape)
{
	posBuf = shape.mesh.positions;
	norBuf = shape.mesh.normals;
	texBuf = shape.mesh.texcoords;
	eleBuf = shape.mesh.indices;
}

void Shape::measure()
{
	float minX, minY, minZ;
	float maxX, maxY, maxZ;

	minX = minY = minZ = std::numeric_limits<float>::infinity();
	maxX = maxY = maxZ = -std::numeric_limits<float>::infinity();

	//Go through all vertices to determine min and max of each dimension
	for (size_t v = 0; v < posBuf.size() / 3; v++)
	{
		if (posBuf[3 * v + 0] < minX) minX = posBuf[3 * v + 0];
		if (posBuf[3 * v + 0] > maxX) maxX = posBuf[3 * v + 0];

		if (posBuf[3 * v + 1] < minY) minY = posBuf[3 * v + 1];
		if (posBuf[3 * v + 1] > maxY) maxY = posBuf[3 * v + 1];

		if (posBuf[3 * v + 2] < minZ) minZ = posBuf[3 * v + 2];
		if (posBuf[3 * v + 2] > maxZ) maxZ = posBuf[3 * v + 2];
	}

	min.x = minX;
	min.y = minY;
	min.z = minZ;
	max.x = maxX;
	max.y = maxY;
	max.z = maxZ;
}

void Shape::computeNormals() {
	std::vector<glm::vec3> vertexNormals(posBuf.size(), glm::vec3(0.0f, 0.0f, 0.0f));
	
	if (posBuf.empty() || eleBuf.empty()) {
		std::cerr << "Error: posBuf or eleBuf is empty, cannot compute normals!" << std::endl;
		return;
	}

	// Initialize normal buffer with zeroes
	norBuf.assign(posBuf.size(), 0.0f);
	for (int i = 0; i < eleBuf.size(); i += 3) {
		int index1 = eleBuf[i];
		int index2 = eleBuf[i + 1];
		int index3 = eleBuf[i + 2];

		glm::vec3 vertex1 = glm::vec3(posBuf[index1 * 3], posBuf[index1 * 3 + 1], posBuf[index1 * 3 + 2]);
		glm::vec3 vertex2 = glm::vec3(posBuf[index2 * 3], posBuf[index2 * 3 + 1], posBuf[index2 * 3 + 2]);
		glm::vec3 vertex3 = glm::vec3(posBuf[index3 * 3], posBuf[index3 * 3 + 1], posBuf[index3 * 3 + 2]);

		glm::vec3 normal = glm::normalize(glm::cross(vertex2 - vertex1, vertex3 - vertex2));

		for (int j : {index1, index2, index3})
		{
			norBuf[j * 3] += normal.x;
			norBuf[j * 3 + 1] += normal.y;
			norBuf[j * 3 + 2] += normal.z;
		}
	}
	// Normalize each vertex normal
	for (size_t i = 0; i < posBuf.size()/3; i++)
	{
		glm::vec3 normal(norBuf[i * 3], norBuf[i * 3 + 1], norBuf[i * 3 + 2]);
		normal = glm::normalize(normal);
		norBuf[i * 3] = normal.x;
		norBuf[i * 3 + 1] = normal.y;
		norBuf[i * 3 + 2] = normal.z;
	}
}

void Shape::init()
{
	// Initialize the vertex array object
	CHECKED_GL_CALL(glGenVertexArrays(1, &vaoID));
	CHECKED_GL_CALL(glBindVertexArray(vaoID));

	// Send the position array to the GPU
	CHECKED_GL_CALL(glGenBuffers(1, &posBufID));
	CHECKED_GL_CALL(glBindBuffer(GL_ARRAY_BUFFER, posBufID));
	CHECKED_GL_CALL(glBufferData(GL_ARRAY_BUFFER, posBuf.size() * sizeof(float), &posBuf[0], GL_STATIC_DRAW));

	// Send the normal array to the GPU
	if (norBuf.empty())
	{
		computeNormals();
	}	

	CHECKED_GL_CALL(glGenBuffers(1, &norBufID));
	CHECKED_GL_CALL(glBindBuffer(GL_ARRAY_BUFFER, norBufID));
	CHECKED_GL_CALL(glBufferData(GL_ARRAY_BUFFER, norBuf.size() * sizeof(float), &norBuf[0], GL_STATIC_DRAW));
	

	// Send the texture array to the GPU
	if (texBuf.empty())
	{
		texBufID = 0;
	}
	else
	{
		CHECKED_GL_CALL(glGenBuffers(1, &texBufID));
		CHECKED_GL_CALL(glBindBuffer(GL_ARRAY_BUFFER, texBufID));
		CHECKED_GL_CALL(glBufferData(GL_ARRAY_BUFFER, texBuf.size() * sizeof(float), &texBuf[0], GL_STATIC_DRAW));
	}

	// Send the element array to the GPU
	CHECKED_GL_CALL(glGenBuffers(1, &eleBufID));
	CHECKED_GL_CALL(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eleBufID));
	CHECKED_GL_CALL(glBufferData(GL_ELEMENT_ARRAY_BUFFER, eleBuf.size() * sizeof(unsigned int), &eleBuf[0], GL_STATIC_DRAW));

	// Unbind the arrays
	CHECKED_GL_CALL(glBindBuffer(GL_ARRAY_BUFFER, 0));
	CHECKED_GL_CALL(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0));

	assert(glGetError() == GL_NO_ERROR);
}

void Shape::textureOff() {
	texBufID = 0;
}

void Shape::draw(const shared_ptr<Program> prog) const
{
	int h_pos, h_nor, h_tex;
	h_pos = h_nor = h_tex = -1;

	CHECKED_GL_CALL(glBindVertexArray(vaoID));

	// Bind position buffer
	h_pos = prog->getAttribute("vertPos");
	GLSL::enableVertexAttribArray(h_pos);
	CHECKED_GL_CALL(glBindBuffer(GL_ARRAY_BUFFER, posBufID));
	CHECKED_GL_CALL(glVertexAttribPointer(h_pos, 3, GL_FLOAT, GL_FALSE, 0, (const void*)0));

	// Bind normal buffer
	h_nor = prog->getAttribute("vertNor");
	if (h_nor != -1 && norBufID != 0)
	{
		GLSL::enableVertexAttribArray(h_nor);
		CHECKED_GL_CALL(glBindBuffer(GL_ARRAY_BUFFER, norBufID));
		CHECKED_GL_CALL(glVertexAttribPointer(h_nor, 3, GL_FLOAT, GL_FALSE, 0, (const void*)0));
	}

	if (texBufID != 0)
	{
		// Bind texcoords buffer
		h_tex = prog->getAttribute("vertTex");

		if (h_tex != -1 && texBufID != 0)
		{
			GLSL::enableVertexAttribArray(h_tex);
			CHECKED_GL_CALL(glBindBuffer(GL_ARRAY_BUFFER, texBufID));
			CHECKED_GL_CALL(glVertexAttribPointer(h_tex, 2, GL_FLOAT, GL_FALSE, 0, (const void*)0));
		}
	}

	// Bind element buffer
	CHECKED_GL_CALL(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eleBufID));

	// Draw
	CHECKED_GL_CALL(glDrawElements(GL_TRIANGLES, (int)eleBuf.size(), GL_UNSIGNED_INT, (const void*)0));

	// Disable and unbind
	if (h_tex != -1)
	{
		GLSL::disableVertexAttribArray(h_tex);
	}
	if (h_nor != -1)
	{
		GLSL::disableVertexAttribArray(h_nor);
	}
	GLSL::disableVertexAttribArray(h_pos);
	CHECKED_GL_CALL(glBindBuffer(GL_ARRAY_BUFFER, 0));
	CHECKED_GL_CALL(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0));
}
