#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import "Shared.h"
#import "MMesh.h"

@class Mesh, Material;

@interface Renderer : NSObject {
    @public id<MTLDevice> device;
    @public id<MTLLibrary> library;
}

@property (strong) UIColor *clearColor;

-(instancetype)initWithView:(UIView *)view;
-(id<MTLTexture>)textureForImage:(UIImage *)image;
-(id<MTLBuffer>)newBufferWithBytes:(const void *)bytes length:(NSUInteger)length;

-(void)startFrame;
-(void)endFrame;

-(void)drawMMesh:(MMesh *)data :(id<MTLBuffer>)uni;

-(void)drawMeshWithInterleavedBuffer:(id<MTLBuffer>)positionBuffer
                              indexBuffer:(id<MTLBuffer>)indexBuffer
                            uniformBuffer:(id<MTLBuffer>)uniformBuffer
                               indexCount:(size_t)indexCount
                                type:(MTLPrimitiveType)indexType;

@end

extern Renderer *renderer;

//MTLPrimitiveTypePoint = 0,
//MTLPrimitiveTypeLine = 1,
//MTLPrimitiveTypeLineStrip = 2,
//MTLPrimitiveTypeTriangle = 3,
//MTLPrimitiveTypeTriangleStrip = 4,
