#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import "Grid.h"
#import "Renderer.h"
#import "Transformations.h"
#import "ViewController.h"

Grid *grid = nil;

@interface Grid ()
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> indexBuffer;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@end

@implementation Grid

-(id)init
{
    self = [super init];
    if(!self) return nil;
    
    float KK = 1;
    colorData.ambientColor = { 1,1,1 };
    colorData.diffuseColor = { KK,KK,KK };
    colorData.specularColor = { 1, 1, 0.8 };
    colorData.alpha = 1;
    _vertexBuffer = nil;
    
    return self;
}

enum {
    VCOUNT = (GXCOUNT+1) * 2 + (GYCOUNT+1) * 2 + 8,
    ICOUNT = VCOUNT
};

static VertexData vData[VCOUNT];
static short iData[ICOUNT];

void setPosition(int index,float x,float y)
{
    vData[index].position.x = GX1 + x;
    vData[index].position.y = GY1 + y;
    vData[index].position.z = 0;
    vData[index].position.w = 1;
}

-(void)initialize
{
    if(_vertexBuffer) return;   // already done

    memset((void *)vData,0,sizeof(vData));
    int vIndex = 0;
    int iIndex = 0;
    float x1,x2,xp,y1,y2,yp;
    
    for(int x=0;x<=GXCOUNT;++x) {
        xp = x * GXS;
        y1 = 0;
        y2 = GYCOUNT * GXS;
        setPosition(vIndex,xp,y1);
        iData[iIndex++] = vIndex++;
        setPosition(vIndex,xp,y2);
        iData[iIndex++] = vIndex++;
    }
    
    for(int y=0;y<=GYCOUNT;++y) {
        x1 = 0;
        x2 = GYCOUNT * GXS;
        yp = y * GXS;
        setPosition(vIndex,x1,yp);
        iData[iIndex++] = vIndex++;
        setPosition(vIndex,x2,yp);
        iData[iIndex++] = vIndex++;
    }

    // center lines
    float cOffset = 0.07;
    xp = GYCOUNT * GXS/2 - cOffset;
    y1 = 0;
    y2 = GYCOUNT * GXS;
    setPosition(vIndex,xp,y1);
    iData[iIndex++] = vIndex++;
    setPosition(vIndex,xp,y2);
    iData[iIndex++] = vIndex++;

    xp = GYCOUNT * GXS/2 + cOffset;
    setPosition(vIndex,xp,y1);
    iData[iIndex++] = vIndex++;
    setPosition(vIndex,xp,y2);
    iData[iIndex++] = vIndex++;

    x1 = 0;
    x2 = GYCOUNT * GXS;
    yp = GYCOUNT * GXS/2 - cOffset;
    setPosition(vIndex,x1,yp);
    iData[iIndex++] = vIndex++;
    setPosition(vIndex,x2,yp);
    iData[iIndex++] = vIndex++;
    
    x1 = 0;
    x2 = GYCOUNT * GXS;
    yp = GYCOUNT * GXS/2 + cOffset;
    setPosition(vIndex,x1,yp);
    iData[iIndex++] = vIndex++;
    setPosition(vIndex,x2,yp);
    iData[iIndex++] = vIndex++;
    
    _vertexBuffer = [renderer newBufferWithBytes:vData length:VCOUNT * sizeof(VertexData)];
    _indexBuffer  = [renderer newBufferWithBytes:iData length:ICOUNT * sizeof(short)];
}

-(void)update:(float4x4)modelView :(float)scale
{
    [self initialize];
    
    Uniforms uniforms;
    uniforms.modelViewMatrix = modelView;
    
    float4x4 modelViewProj = globalProjectionMatrix * modelView;
    uniforms.modelViewProjectionMatrix = modelViewProj;
    
    colorData.diffuseColor = { 1,1,1 };
    uniforms.material = colorData;
    uniforms.scale = scale;
    uniforms.textured = false;
 
    _uniformBuffer = [renderer newBufferWithBytes:(void *)&uniforms length:sizeof(Uniforms)];
}

-(void)draw
{
    [renderer drawMeshWithInterleavedBuffer:_vertexBuffer
                                indexBuffer:_indexBuffer
                              uniformBuffer:_uniformBuffer
                                 indexCount:ICOUNT
                                       type:MTLPrimitiveTypeLine];
}

@end
