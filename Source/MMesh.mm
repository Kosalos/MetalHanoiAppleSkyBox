#import <QuartzCore/CAMetalLayer.h>
#import "MMesh.h"
#import "ViewController.h"
#import "Renderer.h"

@implementation MMesh

-(instancetype)initWithVertexData:(VertexData *)vData
                      vertexCount:(int)vCount
                        indexData:(short *)iData
                       indexCount:(int)iCount
                 vertexShaderName:(NSString *)vShaderName
               fragmentShaderName:(NSString *)fShaderName
                      textureName:(NSString *)textureName
{
    self = [super init];
    if(!self) ABORT;
    if(!renderer || !vData || (vCount <= 0) || !iData || (iCount <= 0) ||
       !vShaderName || !fShaderName || !textureName) ABORT;
    
    colorData.ambientColor = { 1,1,1 };
    colorData.diffuseColor = { .7,.7,.7 };
    colorData.specularColor = { 1, 1, 0.8 };
    colorData.alpha = 1;
    textured = true;
    
    _vertexBuffer = [renderer->device newBufferWithBytes:vData
                                                  length:vCount * sizeof(VertexData)
                                                 options:MTLResourceOptionCPUCacheModeDefault];
    if(!_vertexBuffer) ABORT;
    
    
    _indexBuffer = [renderer->device newBufferWithBytes:iData
                                                 length:iCount * sizeof(short)
                                                options:MTLResourceOptionCPUCacheModeDefault];
    if(!_indexBuffer) ABORT;
    
    _vertexFunction = [renderer->library newFunctionWithName:vShaderName];
    if(!_vertexFunction) ABORT;
    
    _fragmentFunction = [renderer->library newFunctionWithName:fShaderName];
    if(!_fragmentFunction) ABORT;
    
    UIImage *image = [UIImage imageNamed:textureName];
    if(!image) ABORT;
    
    _texture = [renderer textureForImage:image];
    if(!_texture) ABORT;
    
    count = iCount;
    
    // pipeline for MVertex ---------------------------------
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].offset = offsetof(VertexData, position);
    
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[1].offset = offsetof(VertexData, normal);
    
    vertexDescriptor.attributes[2].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[2].bufferIndex = 0;
    vertexDescriptor.attributes[2].offset = offsetof(VertexData, texCoords);
    
    vertexDescriptor.layouts[0].stride = sizeof(VertexData);
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    pipelineDescriptor.vertexFunction = _vertexFunction;
    pipelineDescriptor.fragmentFunction = _fragmentFunction;
    
    // prepare for alpha blending
    MTLRenderPipelineColorAttachmentDescriptor *cc = pipelineDescriptor.colorAttachments[0];
    cc.pixelFormat = MTLPixelFormatBGRA8Unorm;
    cc.blendingEnabled = YES;
    cc.rgbBlendOperation = MTLBlendOperationAdd;
    cc.alphaBlendOperation = MTLBlendOperationAdd;
    cc.sourceRGBBlendFactor = MTLBlendFactorOne;
    cc.sourceAlphaBlendFactor = MTLBlendFactorOne;
    cc.destinationRGBBlendFactor =   MTLBlendFactorOneMinusSourceAlpha;
    cc.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    NSError *error = nil;
    _pipeline = [renderer->device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if(!_pipeline) ABORT;
    
    return self;
}

-(void)draw :(float4x4)modelView :(float)scale
{
    Uniforms uniforms;
    uniforms.modelViewMatrix = modelView;
    
    float4x4 modelViewProj = globalProjectionMatrix * modelView;
    uniforms.modelViewProjectionMatrix = modelViewProj;
    
    float3x3 normalMatrix = { modelView.columns[0].xyz, modelView.columns[1].xyz, modelView.columns[2].xyz };
    uniforms.normalMatrix = transpose(inverse(normalMatrix));
    
    uniforms.material = colorData;
    uniforms.textured = textured;
    uniforms.scale = scale;
    
    for(int i=0;i<NUM_LIGHT;++i)
        uniforms.light[i] = globalLight[i];
    
    
    id<MTLBuffer> uniformBuffer = [renderer newBufferWithBytes:(void *)&uniforms length:sizeof(Uniforms)];
    
    [renderer drawMMesh:self:uniformBuffer];
}

@end
