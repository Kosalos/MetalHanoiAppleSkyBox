#include <metal_stdlib>
#include <metal_matrix>
#include "Shared.h"

using namespace metal;

constant float3 kSpecularColor= { 1, 1, 1 };

struct TouchPt
{
    float result[[attribute(0)]];
};

struct Vertex
{
    float4 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct ProjectedVertex
{
    float4 position [[position]];
    float3 eyePosition;
    float3 normal;
    float2 texCoords;
};

vertex ProjectedVertex vertex_main(
    Vertex vert [[stage_in]],
    constant Uniforms &uniforms [[buffer(1)]])
{
    ProjectedVertex outVert;

    if(uniforms.scale != 1.0) {
        vert.position.x =  vert.position.x * uniforms.scale;
        vert.position.y =  vert.position.y * uniforms.scale;
        vert.position.z =  vert.position.z * uniforms.scale;
    }
    
    outVert.position = uniforms.modelViewProjectionMatrix * vert.position;
    
    outVert.eyePosition = -(uniforms.modelViewMatrix * vert.position).xyz;
    
    if(uniforms.textured) {
        outVert.normal = uniforms.normalMatrix * vert.normal;
        outVert.texCoords = vert.texCoords;
    }
    
    return outVert;
}

#define CAST(n) (*(constant float3 *)&n)

fragment float4 fragment_main(
    ProjectedVertex vert [[stage_in]],
    constant Uniforms &uniforms [[buffer(0)]],
    texture2d<float> diffuseTexture [[texture(0)]],
    sampler samplr [[sampler(0)]])
{
    float3 diffuseColor;
    
    if(!uniforms.textured)
        return float4(uniforms.material.diffuseColor,uniforms.material.alpha);
    
    if(uniforms.textured)
        diffuseColor = diffuseTexture.sample(samplr, vert.texCoords).rgb * CAST(uniforms.material.diffuseColor);
    else
        diffuseColor = uniforms.material.diffuseColor;

    float3 ambientTerm = CAST(uniforms.light[0].ambientColor) * diffuseColor;
    
//    float3 normal = normalize(vert.normal);
    float3 hk =  normalize((diffuseColor * 2.0f - 1.0f));  float3 normal = normalize(hk * vert.normal);
    
    float3 eyeDirection = normalize(vert.eyePosition);

    float3 specularTerm(0);
    float3 diffuseTerm(0);

    for(int i=0;i<NUM_LIGHT;++i) {
        if(!uniforms.light[i].active) continue;
        
        float diffuseIntensity = saturate(dot(normal, CAST(uniforms.light[i].direction)));
        diffuseTerm = diffuseTerm + CAST(uniforms.light[i].diffuseColor) * diffuseColor * diffuseIntensity;
        
        if(diffuseIntensity > 0) {
            float3 halfway = normalize(CAST(uniforms.light[i].direction) + eyeDirection);
            float specularFactor = pow(saturate(dot(normal, halfway)), uniforms.light[i].specularPower);
            specularTerm = specularTerm + CAST(uniforms.light[i].specularColor) * kSpecularColor * specularFactor;
        }
    }
    
    diffuseTerm = saturate(diffuseTerm);
    specularTerm = saturate(specularTerm);
    
    return float4(ambientTerm + diffuseTerm + specularTerm,uniforms.material.alpha);
}
