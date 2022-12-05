#include "Camera.h"
#include <glm/gtx/quaternion.hpp>
Camera::Camera()
{
	Position = glm::vec3{ 0.0f,0.0f,-0.2f };
	ViewMatrix = glm::lookAt(Position, glm::vec3{0.0f,0.0f,0.0f}, glm::vec3{ 0.0f,1.0f,0.0f });
	m_ProjectionMatrix = glm::mat4(1.0f); 
	CameraMatrix = ViewMatrix; 
}

Camera::Camera(const glm::mat4& projection)
{
	ViewMatrix = glm::mat4(1.0f); 
	m_ProjectionMatrix = projection ; 
	Position = glm::vec3(0.0f); 
	update_cameramatrix();
}

Camera::~Camera()
{

}

void Camera::move_displacement(const glm::vec3& displacement)
{
	Position = Position + displacement; 
	ViewMatrix = glm::lookAt(Position, glm::vec3{ 0.0f,0.0f,0.0f }, glm::vec3{ 0.0f,1.0f,0.0f });
	update_cameramatrix(); 
}

void Camera::move_to_point(const glm::vec3& pointPosition)
{
	Position = pointPosition; 
	ViewMatrix = glm::mat4(glm::mat3(ViewMatrix)); 
	ViewMatrix[3] = glm::vec4{ -Position ,1};
	update_cameramatrix(); 
}

void Camera::orient(const glm::quat& rpy)
{
	ViewMatrix = glm::transpose(glm::toMat4(rpy)) * ViewMatrix; 
	update_cameramatrix(); 
}

void Camera::orient(const glm::mat4& rot4x4)
{
	ViewMatrix = glm::transpose(rot4x4); 
	update_cameramatrix(); 
}

void Camera::rotate(const glm::mat4& rot4x4)
{
	ViewMatrix = glm::transpose(rot4x4) * ViewMatrix; 
	update_cameramatrix(); 
}

void Camera::rotate(const glm::quat& quat)
{
	ViewMatrix = glm::transpose(glm::toMat4(quat)) * ViewMatrix; 
	update_cameramatrix(); 
}
void Camera::update_cameramatrix() { CameraMatrix = m_ProjectionMatrix * ViewMatrix;  }

void Camera::set_projection_matrix(const glm::mat4& projection)
{
	m_ProjectionMatrix = projection; 
	update_cameramatrix(); 
}

OrthographicCamera::OrthographicCamera(OrthographicSpecifications spec)
{
	m_Specs = spec; 
	this->m_ProjectionMatrix = glm::ortho(m_Specs.left, m_Specs.right, m_Specs.bottom, m_Specs.top, m_Specs.zNear, m_Specs.zFar);
}

OrthographicCamera::~OrthographicCamera()
{
}

void OrthographicCamera::SetSpecs(OrthographicSpecifications spec)
{
	m_Specs = spec;
	this->m_ProjectionMatrix = glm::ortho(m_Specs.left, m_Specs.right, m_Specs.bottom, m_Specs.top, m_Specs.zNear, m_Specs.zFar);

}

glm::mat4& OrthographicCamera::get_cameramatrix()
{
	return this->m_ProjectionMatrix;
}

void OrthographicCamera::Zoom(float scale, float x, float y)
{
		m_Specs.m_Scale = scale; 
		this->m_ProjectionMatrix = glm::scale(glm::translate(m_ProjectionMatrix, glm::vec3{-x,y, 0 } * 0.05f), glm::vec3{ scale,scale,1.0f });
}

void OrthographicCamera::Reset()
{

}

PerspectiveCamera::PerspectiveCamera()
{

}

PerspectiveCamera::~PerspectiveCamera()
{

}