// hanoiBase.h

#pragma once
#import "Shared.h"

enum {
	VERTEXCOUNT_hanoiBase = 110,
	INDEXCOUNT_hanoiBase = 648,
};

/*
typedef struct {
	float4 position;
	float3 normal;
	float2 texCoords;
} VertexData;

*/
extern VertexData vertex_hanoiBase[VERTEXCOUNT_hanoiBase];
extern short indice_hanoiBase[INDEXCOUNT_hanoiBase];

#define VERTEXLENGTH_hanoiBase (VERTEXCOUNT_hanoiBase * sizeof(VertexData))
#define INDEXLENGTH_hanoiBase (INDEXCOUNT_hanoiBase * sizeof(short))
