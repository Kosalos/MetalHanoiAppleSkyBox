#import <QuartzCore/CAMetalLayer.h>
#import "Renderer.h"
#import "Transformations.h"
#import "SkyBox.h"
//#import "AAPLTransforms.h"

Renderer *renderer = nil;

@interface Renderer ()

@property (strong) UIView *view;
@property (weak) CAMetalLayer *layer;
@property (strong) id<MTLTexture> depthTexture;
@property (strong) id<MTLSamplerState> sampler;
@property (strong) MTLRenderPassDescriptor *currentRenderPass;
@property (strong) id<CAMetalDrawable> currentDrawable;

@property (strong) id<MTLCommandQueue> commandQueue;
@property (strong) id<MTLCommandBuffer> commandBuffer;
@property (strong) id<MTLRenderCommandEncoder> commandEncoder;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;

@end

id<MTLRenderPipelineState> pipeline;

@implementation Renderer

-(instancetype)initWithView:(UIView *)view
{
    if ((self = [super init]))
    {
        renderer = self;
        
        NSAssert([view.layer isKindOfClass:[CAMetalLayer class]], @"Layer type of view used for rendering must be CAMetalLayer");

        _view = view;
        _layer = (CAMetalLayer *)view.layer;
        _clearColor = [UIColor colorWithWhite:0.95 alpha:1];
        device = MTLCreateSystemDefaultDevice();
        [self initializeDeviceDependentObjects];
    }
    return self;
}

-(void)initializeDeviceDependentObjects
{
    library = [device newDefaultLibrary];
    
    _commandQueue = [device newCommandQueue];
    
    // skybox -----------------------------
    skyBox.loadAssets(device,library);
    
    //0 	Positive X
    //1 	Negative X
    //2 	Positive Y
    //3 	Negative Y
    //4 	Positive Z
    //5 	Negative Z

//        NSArray *imageNames = @[
//                @"rt.png",@"lf.png",
//                @"up.png",@"dn.png",
//                @"bk.png",@"ft.png"];
    
    NSArray *imageNames = @[
                            @"jajsundown1_right.jpg",
                            @"jajsundown1_left.jpg",
                            @"jajsundown1_top.jpg",
                            @"jajsundown1_top.jpg",
                            @"jajsundown1_front.jpg",
                            @"jajsundown1_back.jpg"];
                            
                            bool loaded = skyBox.load6Textures(device,imageNames);
    
//    bool loaded = skyBox.loadTexture(device,@"skybox");
    if (!loaded)
        NSLog(@"failed to load skybox texture");
    
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    _sampler = [device newSamplerStateWithDescriptor:samplerDescriptor];
}

-(id<MTLTexture>)textureForImage:(UIImage *)image
{
    CGImageRef imageRef = [image CGImage];
    
    // Create a suitable bitmap context for extracting the bits of the image
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8_t *rawData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);

    // Flip the context so the positive Y axis points down
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    MTLTextureDescriptor *textureDescriptor =
    [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                       width:width
                                                      height:height
                                                   mipmapped:YES];
    id<MTLTexture> texture = [device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [texture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];

    free(rawData);

    return texture;
}

-(void)createDepthBuffer
{
    CGSize drawableSize = self.layer.drawableSize;
    MTLTextureDescriptor *depthTexDesc =
    [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                       width:drawableSize.width
                                                      height:drawableSize.height
                                                   mipmapped:NO];
    self.depthTexture = [device newTextureWithDescriptor:depthTexDesc];
}

-(id<MTLBuffer>)newBufferWithBytes:(const void *)bytes length:(NSUInteger)length
{
    return [device newBufferWithBytes:bytes
                               length:length
                              options:MTLResourceOptionCPUCacheModeDefault];
}

extern float4x4 eyePositionMatrix();
extern float4x4 globalProjectionMatrix;

extern float3 eyeAngle;

float4x4 sbeyePositionMatrix()
{
    float4x4 mvm = RotationY(-eyeAngle.y);
 //   mvm = mvm * RotationZ(eyeAngle.x);
    return mvm;
}

-(void)startFrame
{
    CGSize drawableSize = self.layer.drawableSize;

    if (!self.depthTexture || self.depthTexture.width != drawableSize.width || self.depthTexture.height != drawableSize.height)
        [self createDepthBuffer];
    
    id<CAMetalDrawable> drawable = [self.layer nextDrawable];  NSAssert(drawable != nil, @"Could not retrieve drawable from Metal layer");
    
    static MTLRenderPassDescriptor *renderPass = nil;
    static MTLDepthStencilDescriptor *depthStencilDescriptor = nil;
    static id<MTLDepthStencilState> depthStencilStateNO;
    static id<MTLDepthStencilState> depthStencilStateYES;
    
    if(!renderPass) {
        renderPass = [MTLRenderPassDescriptor renderPassDescriptor];

        renderPass.colorAttachments[0].loadAction = MTLLoadActionDontCare;
        renderPass.colorAttachments[0].storeAction = MTLStoreActionStore;
        
//        float cc = 20.0/256.0;
//        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(cc,cc,cc*3,1);

        renderPass.depthAttachment.texture = self.depthTexture;
        renderPass.depthAttachment.loadAction = MTLLoadActionClear;
        renderPass.depthAttachment.storeAction = MTLStoreActionStore;
        renderPass.depthAttachment.clearDepth = 1;
        
        depthStencilDescriptor = [MTLDepthStencilDescriptor new];
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
        depthStencilDescriptor.depthWriteEnabled = NO;
        depthStencilStateNO = [device newDepthStencilStateWithDescriptor:depthStencilDescriptor];

        depthStencilDescriptor.depthWriteEnabled = YES;
        depthStencilStateYES = [device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    }
    renderPass.colorAttachments[0].texture = drawable.texture;
    
    self.currentDrawable = drawable;
    self.currentRenderPass = renderPass;

    _commandBuffer = [self.commandQueue commandBuffer];
    
    _commandEncoder = [_commandBuffer renderCommandEncoderWithDescriptor:self.currentRenderPass];
    [_commandEncoder setCullMode:MTLCullModeBack];
    [_commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [_commandEncoder setDepthStencilState:depthStencilStateNO];

    // sky -----------------------------------
    Uniforms uniforms;
    uniforms.modelViewProjectionMatrix = globalProjectionMatrix * sbeyePositionMatrix();
    id<MTLBuffer> uniformBuffer = [renderer newBufferWithBytes:(void *)&uniforms length:sizeof(Uniforms)];
    skyBox.draw(uniformBuffer,_commandEncoder,_view);

    [_commandEncoder setDepthStencilState:depthStencilStateYES];
}

-(void)endFrame
{
    [_commandEncoder endEncoding];
    [_commandBuffer presentDrawable:self.currentDrawable];
    [_commandBuffer commit];
}

-(void)drawMMesh:(MMesh *)data :(id<MTLBuffer>)uni
{
    [_commandEncoder setVertexBuffer:uni offset:0 atIndex:1];
    [_commandEncoder setFragmentBuffer:uni offset:0 atIndex:0];
    [_commandEncoder setVertexBuffer:data.vertexBuffer offset:0 atIndex:0];
    
    [_commandEncoder setFragmentTexture:data.texture atIndex:0];
    [_commandEncoder setFragmentSamplerState:self.sampler atIndex:0];
    [_commandEncoder setRenderPipelineState:data.pipeline];
    
    [_commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle // LineStrip
                                indexCount:data->count
                                 indexType:MTLIndexTypeUInt16
                               indexBuffer:data.indexBuffer
                         indexBufferOffset:0];
    
}

-(void)drawMeshWithInterleavedBuffer:(id<MTLBuffer>)positionBuffer
                         indexBuffer:(id<MTLBuffer>)indexBuffer
                       uniformBuffer:(id<MTLBuffer>)uniformBuffer
                          indexCount:(size_t)indexCount
                                type:(MTLPrimitiveType)meshType
{
    [_commandEncoder setVertexBuffer:positionBuffer offset:0 atIndex:0];
    [_commandEncoder setVertexBuffer:uniformBuffer offset:0 atIndex:1];
    [_commandEncoder setFragmentBuffer:uniformBuffer offset:0 atIndex:0];
    
    [_commandEncoder drawIndexedPrimitives:meshType
                                indexCount:indexCount
                                 indexType:MTLIndexTypeUInt16
                               indexBuffer:indexBuffer
                         indexBufferOffset:0];
}

@end
