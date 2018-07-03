#include "SkyBox.h"
#import "AAPLTexture.h"

SkyBox skyBox;

using namespace simd;

static const float4 cubeVertexData[] =
{
    // posx
    { -1.0f,  1.0f,  1.0f, 1.0f },
    { -1.0f, -1.0f,  1.0f, 1.0f },
    { -1.0f,  1.0f, -1.0f, 1.0f },
    { -1.0f, -1.0f, -1.0f, 1.0f },
    
    // negz
    { -1.0f,  1.0f, -1.0f, 1.0f },
    { -1.0f, -1.0f, -1.0f, 1.0f },
    { 1.0f,  1.0f, -1.0f, 1.0f },
    { 1.0f, -1.0f, -1.0f, 1.0f },
    
    // negx
    { 1.0f,  1.0f, -1.0f, 1.0f },
    { 1.0f, -1.0f, -1.0f, 1.0f },
    { 1.0f,  1.0f,  1.0f, 1.0f },
    { 1.0f, -1.0f,  1.0f, 1.0f },
    
    // posz
    { 1.0f,  1.0f,  1.0f, 1.0f },
    { 1.0f, -1.0f,  1.0f, 1.0f },
    { -1.0f,  1.0f,  1.0f, 1.0f },
    { -1.0f, -1.0f,  1.0f, 1.0f },
    
    // posy
    { 1.0f,  1.0f, -1.0f, 1.0f },
    { 1.0f,  1.0f,  1.0f, 1.0f },
    { -1.0f,  1.0f, -1.0f, 1.0f },
    { -1.0f,  1.0f,  1.0f, 1.0f },
    
    // negy
    { 1.0f, -1.0f,  1.0f, 1.0f },
    { 1.0f, -1.0f, -1.0f, 1.0f },
    { -1.0f, -1.0f,  1.0f, 1.0f },
    { -1.0f, -1.0f, -1.0f, 1.0f },
};


void SkyBox::loadAssets(
                        id <MTLDevice> device,
                        id <MTLLibrary> library)
{
    id <MTLFunction> vertexProgram = [library newFunctionWithName:@"skyboxVertex"];
    id <MTLFunction> fragmentProgram = [library newFunctionWithName:@"skyboxFragment"];
    
    //  create a pipeline state for the skybox
    MTLRenderPipelineDescriptor *skyboxPipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    skyboxPipelineStateDescriptor.label = @"SkyboxPipelineState";
    
    // the pipeline state must match the drawable framebuffer we are rendering into
    skyboxPipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    skyboxPipelineStateDescriptor.depthAttachmentPixelFormat      = MTLPixelFormatDepth32Float;
    skyboxPipelineStateDescriptor.sampleCount                     = 1; 
    
    // attach the skybox shaders to the pipeline state
    skyboxPipelineStateDescriptor.vertexFunction   = vertexProgram;
    skyboxPipelineStateDescriptor.fragmentFunction = fragmentProgram;
    
    // finally, read out the pipeline state
    _skyboxPipelineState = [device newRenderPipelineStateWithDescriptor:skyboxPipelineStateDescriptor error:nil];
    if(!_skyboxPipelineState) {
        NSLog(@">> ERROR: Couldnt create a pipeline");
        assert(0);
    }
    
    // create the skybox vertex buffer
    _skyboxVertexBuffer = [device newBufferWithBytes:cubeVertexData length:sizeof(cubeVertexData) options:MTLResourceOptionCPUCacheModeDefault];
    _skyboxVertexBuffer.label = @"SkyboxVertexBuffer";
}

bool SkyBox::load6Textures(id <MTLDevice> device,NSArray *imageNames)
{
    _skyboxTex = [[AAPLTextureCubeMap alloc] init];
    [_skyboxTex loadIntoTextureWithPngs:imageNames device:device];
    return true;
    
//    _skyboxTex = [[AAPLTextureCubeMap alloc] initWithResourceName:pngName extension:@"png"];
//    return [_skyboxTex loadIntoTextureWithDevice:device];
}

void SkyBox::draw(id <MTLBuffer> inflightBuffer,id <MTLRenderCommandEncoder> renderEncoder,UIView *view)
{
    [renderEncoder setRenderPipelineState:_skyboxPipelineState];
    
    [renderEncoder setVertexBuffer:_skyboxVertexBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:_skyboxVertexBuffer offset:0 atIndex:1];
    [renderEncoder setVertexBuffer:inflightBuffer offset:0 atIndex:2];
    
    [renderEncoder setFragmentTexture:_skyboxTex.texture atIndex:0];
    
    [renderEncoder drawPrimitives: MTLPrimitiveTypeTriangleStrip vertexStart: 0 vertexCount: 24];
}

