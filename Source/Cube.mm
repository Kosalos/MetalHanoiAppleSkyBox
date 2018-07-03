#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import "Cube.h"
#import "Renderer.h"
#import "Transformations.h"
#import "ViewController.h"
#import "MMesh.h"

Cube *cube = nil;

static MMesh *cubeMesh = nil;

#define NUM_POINTS (6 * 2 * 3)  // 6 faces, 2 triangles each, 3 points per triangle

#define PM (-.5)
#define PP (+.5)

static VertexData vData[NUM_POINTS] = {
    // x,y,z,w          nx,ny,nz        u,v
    { { PM,PM,PM,1 },   { PM,PM,PM },  { 1,0 }},	// front  1 = top
    { { PP,PM,PM,1 },	{ PP,PM,PM },  { 0,0 }},
    { { PM,PP,PM,1 },	{ PM,PP,PM },  { 1,1 }},
    { { PP,PM,PM,1 },	{ PP,PM,PM },  { 0,0 }},
    { { PP,PP,PM,1 },	{ PP,PP,PM },  { 0,1 }},
    { { PM,PP,PM,1 },	{ PM,PP,PM },  { 1,1 }},
    
    { { PP,PM,PP,1 },	{ PP,PM,PP },  { 1,0 }},	// back   2
    { { PM,PM,PP,1 },	{ PM,PM,PP },  { 0,0 }},
    { { PM,PP,PP,1 },	{ PM,PP,PP },  { 0,1 }},
    { { PP,PM,PP,1 },	{ PP,PM,PP },  { 1,0 }},
    { { PM,PP,PP,1 },	{ PM,PP,PP },  { 0,1 }},
    { { PP,PP,PP,1 },	{ PP,PP,PP },  { 1,1 }},
    
    { { PM,PM,PP,1 },	{ PM,PM,PP },  { 1,0 }},	// left   3
    { { PM,PM,PM,1 },	{ PM,PM,PM },  { 0,0 }},
    { { PM,PP,PP,1 },	{ PM,PP,PP },  { 1,1 }},
    { { PM,PM,PM,1 },	{ PM,PM,PM },  { 0,0 }},
    { { PM,PP,PM,1 },	{ PM,PP,PM },  { 0,1 }},
    { { PM,PP,PP,1 },	{ PM,PP,PP },  { 1,1 }},
    
    { { PP,PM,PM,1 },	{ PP,PM,PM },  { 1,0 }},	// right  4
    { { PP,PM,PP,1 },	{ PP,PM,PP },  { 0,0 }},
    { { PP,PP,PP,1 },	{ PP,PP,PP },  { 0,1 }},
    { { PP,PM,PM,1 },	{ PP,PM,PM },  { 1,0 }},
    { { PP,PP,PP,1 },	{ PP,PP,PP },  { 0,1 }},
    { { PP,PP,PM,1 },	{ PP,PP,PM },  { 1,1 }},
    
    { { PM,PM,PP,1 },	{ PM,PP,PP },  { 1,1 }},    // top    5
    { { PP,PM,PM,1 },	{ PP,PP,PM },  { 0,0 }},
    { { PM,PM,PM,1 },	{ PM,PP,PM },  { 1,0 }},
    { { PM,PM,PP,1 },	{ PM,PP,PP },  { 1,1 }},
    { { PP,PM,PP,1 },	{ PP,PP,PP },  { 0,1 }},
    { { PP,PM,PM,1 },	{ PP,PP,PM },  { 0,0 }},

    { { PM,PP,PM,1 },	{ PM,PP,PM },  { 1,0 }},	// bottom 6
    { { PP,PP,PM,1 },	{ PP,PP,PM },  { 0,0 }},
    { { PM,PP,PP,1 },	{ PM,PP,PP },  { 1,1 }},
    { { PP,PP,PM,1 },	{ PP,PP,PM },  { 0,0 }},
    { { PP,PP,PP,1 },	{ PP,PP,PP },  { 0,1 }},
    { { PM,PP,PP,1 },	{ PM,PP,PP },  { 1,1 }},
};

static short iData[NUM_POINTS] = {
    35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
};

@implementation Cube

-(id)init
{
    self = [super init];
    if(!self) return nil;

    colorData.ambientColor = { 1,1,1 };
    colorData.diffuseColor = { 1,1,1 };
    colorData.specularColor = { 0,0,0 }; //1, 1, 0.8 };
    colorData.alpha = 1;
    
    if(!cubeMesh)
        cubeMesh = [[MMesh alloc]
                    initWithVertexData:vData
                    vertexCount:NUM_POINTS
                    indexData:iData
                    indexCount:NUM_POINTS
                    vertexShaderName:@"vertex_main"
                    fragmentShaderName:@"fragment_main"
                    textureName:@"p19"];
    
    return self;
}

-(void)draw :(float4x4)mvm :(float)scale
{
    cubeMesh->colorData = colorData;
    cubeMesh->textured = true;
    [cubeMesh draw:mvm:scale];
}

@end
