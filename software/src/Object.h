#pragma once
#include <glm/glm.hpp>
#include <glm/gtc/epsilon.hpp>
#include <vector>
struct VertexAttributes {
	glm::vec3 VertexPosition;
	glm::vec3 Normal; 
	glm::vec3 Color; // color is always 0 
};  

class Object {
public:


	Object() {}; 
	~Object();
	Object(const Object& obj) : Vertices(obj.Vertices) { }// copy ctr
	Object(Object&& obj) noexcept : Vertices(std::move(obj.Vertices))  {}

	Object& operator=(Object&& obj) noexcept { 
		this->Vertices = std::move(obj.Vertices); 
	}
	
	void Translate(const glm::vec3& displacement); 
	void Rotate(const glm::quat& quaternion);
	void ResizeX(float scale); 
	void ResizeY(float scale); 
	void ResizeZ(float scale); 
	void Rotate(const glm::mat3& rot3x3);
	void SetTextureSlot(float texslot = 0); 
	void SetColor(glm::vec4 color); 
	unsigned int get_vertex_count() const  { return Vertices.size(); }
	std::vector<uint32_t>& get_indices() { return Indices; }
	glm::mat4& get_model_matrix()  { return ModelMatrix; }
	uint32_t get_index_count() const { return Indices.size(); }
	std::vector<VertexAttributes>& get_vertices() { return Vertices;  }

protected: 
	static glm::vec3 CalculateNormal(glm::vec3 p1, glm::vec3 p2, glm::vec3 p3); 
	glm::mat4 ModelMatrix{ 1.0f };
	std::vector<VertexAttributes> Vertices;
	std::vector<uint32_t> Indices; 
};

class PrimitiveObject {

public: 
	class Quad : public Object {
		struct QuadSpecifications {
			float width, height;
			glm::vec3 position;
		};
	private:
		QuadSpecifications m_QuadSpecs = { 1.0f,1.0f,glm::vec3(0.0f) };
	public:
		~Quad(); 
		Quad(); 
		Quad(QuadSpecifications spec);
		Quad(const Quad& quad);
		Quad& operator=(Quad& obj) noexcept {
			this->Vertices = std::move(obj.Vertices);
			this->m_QuadSpecs = std::move(obj.m_QuadSpecs); 
		}
		void MoveToPoint(const glm::vec3& pos); 
		void SetSpec(QuadSpecifications spec); 
	};
	class Triangle : public Object {
	private:
		
	public:


	};
	class Cube : public Object {
		struct CubeSpecifications {
			float size;
			glm::vec3 position{ };
			// TextureID and UVs; 
		};
		
	private:
		CubeSpecifications m_CubeSpecs;
		PrimitiveObject::Quad* m_QuadSides; 
	public:
		Cube(CubeSpecifications spec = CubeSpecifications{ 1.0f,glm::vec3(0.0f) }) ; 
		Cube(const Cube& cube) = default;
		~Cube();
	};

	class Cylinder : public Object {
	private: 

	public: 
	};

};


class Mesh {
	private: 
	public: 
		static void LoadMesh(); 
};