#include <metal_texture>
#include "Shared.h"

using namespace metal;

struct CubeVertexOutput
{
    float4 position [[position]];
    float3 texCoords;
};

vertex
CubeVertexOutput skyboxVertex(
    constant float4 *pos_data [[ buffer(0) ]],
    constant float4 *texcoord [[ buffer(1) ]],
    constant Uniforms &uniforms [[buffer(2)]],
    uint vid [[vertex_id]])
{
    CubeVertexOutput out;
    out.position = uniforms.modelViewProjectionMatrix * pos_data[vid];
    out.texCoords = texcoord[vid].xyz;
    return out;
}

fragment half4
skyboxFragment(
    CubeVertexOutput in [[stage_in]],
    texturecube<half> skybox_texture [[texture(0)]])
{
    constexpr sampler s_cube(filter::linear, mip_filter::linear);
    return skybox_texture.sample(s_cube, in.texCoords);
}
