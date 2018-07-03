#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "Shared.h"

@interface MMesh : NSObject {
@public
    bool textured;
    unsigned long count;
    ColorData colorData;
}

@property (strong) id<MTLBuffer>    vertexBuffer;
@property (strong) id<MTLBuffer>    indexBuffer;
@property (strong) id<MTLFunction>  vertexFunction;
@property (strong) id<MTLFunction>  fragmentFunction;
@property (strong) id<MTLTexture>   texture;
@property (strong) id<MTLRenderPipelineState> pipeline;

-(instancetype)initWithVertexData:(VertexData *)vData
                     vertexCount:(int)vCount
                        indexData:(short *)iData
                      indexCount:(int)iCount
                 vertexShaderName:(NSString *)vShaderName
               fragmentShaderName:(NSString *)fShaderName
                      textureName:(NSString *)textureName;

-(void)draw :(float4x4)modelView :(float)scale;

@end
