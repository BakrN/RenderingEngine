#pragma once
#include <glm/glm.hpp>
#include <glm/ext.hpp>
#include <glm/common.hpp>

class Camera {
	//camera is alwas at 0,0,0 and we 
private: 
	friend class OrthographicCamera; 
	friend class PerspectiveCamera; 
	glm::mat4 m_ProjectionMatrix; // into NDC cube (Image plane with z values between [-1 1] 
	//pinhole method so in view we need 
	glm::vec3 Position; 
	glm::mat4 ViewMatrix; // lookat(position of camera, direction of camera, up vector (y-axis)
	glm::mat4 CameraMatrix;
public: 

	Camera(); 
	Camera(const glm::mat4& projection); 
	~Camera(); 
	Camera(const Camera& cam) = default; 
	Camera(Camera&& cam) = default; 
	void move_displacement(const glm::vec3&  displacement); 
	void move_to_point    (const glm::vec3& pointPosition); 
	void orient(const glm::quat&  rpy); 
	void orient(const glm::mat4&  rot4x4); 
	void rotate(const glm::mat4&  rot4x4); 
	void rotate(const glm::quat& quat); 
	void update_cameramatrix(); 
	void set_projection_matrix(const glm::mat4& projection);
	
	virtual void Zoom(float scale, float x, float y) = 0; 
	virtual glm::mat4& get_cameramatrix() {  return CameraMatrix;  };
};

class OrthographicCamera : public Camera {
	// Note: Move the zoom reset funcs to camera class and have them be virtual 
private:
	struct OrthographicSpecifications {
		float left, right, top, bottom, zNear, zFar, m_Scale;
	};

	OrthographicSpecifications m_Specs = {};
public: 

	OrthographicCamera(OrthographicSpecifications spec = OrthographicSpecifications{ -1.0f , 1.0f , 1.0f , -1.0f , -1.0f , 1.0f , 1.0f });
	~OrthographicCamera();
	void SetSpecs(OrthographicSpecifications spec); 
	virtual glm::mat4& get_cameramatrix() override; 
	virtual void Zoom(float scale, float x, float y) override; 
	void Reset(); 
};

class PerspectiveCamera : Camera {

public: 
	PerspectiveCamera();  

	~PerspectiveCamera(); 
};