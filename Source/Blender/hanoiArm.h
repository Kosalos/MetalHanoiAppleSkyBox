// hanoiArm.h

#pragma once

#import "Shared.h" // include <simd/simd.h>

enum {
	VERTEXCOUNT_hanoiArm = 124,
	INDEXCOUNT_hanoiArm = 780,
};

/*
typedef struct {
	float4 position;
	float3 normal;
	float2 texCoords;
} VertexData;

*/
extern VertexData vertex_hanoiArm[VERTEXCOUNT_hanoiArm];
extern short indice_hanoiArm[INDEXCOUNT_hanoiArm];

#define VERTEXLENGTH_hanoiArm (VERTEXCOUNT_hanoiArm * sizeof(VertexData))
#define INDEXLENGTH_hanoiArm (INDEXCOUNT_hanoiArm * sizeof(short))
