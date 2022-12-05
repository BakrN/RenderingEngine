#pragma once
#include "Object.h"

struct RenderStats {
	uint32_t m_DrawCount = 0;
	uint32_t m_DrawCalls = 0;
	void ResetStats() {
		m_DrawCount = 0;
		m_DrawCalls = 0; 
	}
};
static class Renderer2D{
private: 
	std::vector<uint32_t> m_Count; 
public: 
	static void Init(); 
	static void Flush();  
	static void Finish(); 
	static void DrawQuad(PrimitiveObject::Quad* quad);
	static void DrawTriangle(PrimitiveObject::Triangle& triangle);  
	static void NewBatch(); 
	static void EndBatch(); 
	static RenderStats GetStats(); 
};