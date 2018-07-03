#import <simd/simd.h>

using namespace simd;

float4x4 Identity();

float4x4 RotationX(float angle);  // right handed
float4x4 RotationY(float angle);
float4x4 RotationZ(float angle);

float4x4 PerspectiveProjection(float aspect, float fovy, float near, float far);

float3x3 UpperLeft3x3(const float4x4 &mat);

float4x4 Translate(float dx,float dy,float dz);
