#pragma once
#include <vector> 
#include <string>  
	enum class AttributeType {
		FLOAT1, 
		FLOAT2,
		FLOAT3,
		FLOAT4,
		UINT1,
		UINT2,
		UINT3,
		UINT4,
		MAT3,
		MAT4
	};

struct BufferElement {
	// needed data is size and stride and type and position i.e pointer 
	BufferElement(const std::string& name, AttributeType type) : Name(name) ,Type(type) , Size(GetSizeByType(type)), Offset(0){};
	
	uint32_t GetSizeByType(AttributeType t) {
		switch (t) {
		case AttributeType::FLOAT1: return sizeof(float) ;
		case AttributeType::FLOAT2: return sizeof(float) * 2;
		case AttributeType::FLOAT3: return sizeof(float) * 3;
		case AttributeType::FLOAT4: return sizeof(float) * 4;
		case AttributeType::UINT1 : return sizeof(uint32_t) * 1;
		case AttributeType::UINT2 : return sizeof(uint32_t) * 2;
		case AttributeType::UINT3 : return sizeof(uint32_t) * 3;
		case AttributeType::UINT4 : return sizeof(uint32_t) * 4;
		case AttributeType::MAT3  : return sizeof(float) * 3 * 3;
		case AttributeType::MAT4  : return sizeof(float) * 4 * 4;
		}
	}
	uint32_t GetCountByType() {
		switch (Type) {
		case AttributeType::FLOAT1: return 1;
		case AttributeType::FLOAT2: return 2;
		case AttributeType::FLOAT3: return 3; 
		case AttributeType::FLOAT4: return 4; 
		case AttributeType::UINT1 : return 1;
		case AttributeType::UINT2 : return 2;
		case AttributeType::UINT3 : return 3;
		case AttributeType::UINT4 : return 4;
		case AttributeType::MAT3  : return 3 * 3;
		case AttributeType::MAT4  : return 4 * 4;
		}

	}
	unsigned int Size;
	std::string Name;
	AttributeType Type; 
	uint32_t Offset; 
};
class BufferLayout {
private: 
	std::vector<BufferElement> m_BufferElements; 
	uint32_t m_Stride= 0; // size; 

public: 
	std::vector<BufferElement>& GetBufferElements()  { return m_BufferElements;  };
	BufferLayout() = default; 
	~BufferLayout() = default; 
	uint32_t GetStride() { return m_Stride;  }
	BufferLayout(const std::initializer_list<BufferElement>& elements) {
		uint32_t offset = 0; 
		m_Stride = 0; 
		for (auto e : elements) {
			e.Offset = offset; 
			offset += e.Size; 
			m_Stride += e.Size; 
			m_BufferElements.push_back(e); 
		}
	};
	std::vector<BufferElement>::iterator begin() { return m_BufferElements.begin();  }
	std::vector<BufferElement>::iterator end() { return m_BufferElements.end();  }

};



class VertexBuffer {
private:
	unsigned int m_BufferId;
	BufferLayout m_Layout; 
public:
	VertexBuffer(const void* data, unsigned int size);
	VertexBuffer(unsigned int size);
	void UpdateData(const void* data, unsigned int size); 
	~VertexBuffer();
	BufferLayout& GetBufferLayout() { return m_Layout;};
	void SetLayout(const BufferLayout& layout) { m_Layout = layout;}
	void Bind() const;
	void UnBind() const;
};