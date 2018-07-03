// hanoiHand.h

#pragma once

#import "Shared.h" // include <simd/simd.h>

enum {
	VERTEXCOUNT_hanoiHand = 101,
	INDEXCOUNT_hanoiHand = 558,
};

/*
typedef struct {
	float4 position;
	float3 normal;
	float2 texCoords;
} VertexData;

*/
extern VertexData vertex_hanoiHand[VERTEXCOUNT_hanoiHand];
extern short indice_hanoiHand[INDEXCOUNT_hanoiHand];

#define VERTEXLENGTH_hanoiHand (VERTEXCOUNT_hanoiHand * sizeof(VertexData))
#define INDEXLENGTH_hanoiHand (INDEXCOUNT_hanoiHand * sizeof(short))
