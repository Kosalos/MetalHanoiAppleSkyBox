#pragma once

#import <Metal/Metal.h>
#import <simd/simd.h>
#import "AAPLTexture.h"

//0 	Positive X
//1 	Negative X
//2 	Positive Y
//3 	Negative Y
//4 	Positive Z
//5 	Negative Z

class SkyBox
{
public:
    void loadAssets(id <MTLDevice> device,id <MTLLibrary>library);
    bool loadTexture(id <MTLDevice> device,NSString *pngName);      // vertical strip of 6 images
    bool load6Textures(id <MTLDevice> device,NSArray *imageNames);  // 6 individual images

    void draw(id <MTLBuffer> inflightBuffer,id <MTLRenderCommandEncoder> renderEncoder,UIView *view);

private:
    AAPLTextureCubeMap *_skyboxTex;
    id <MTLRenderPipelineState> _skyboxPipelineState;
    id <MTLBuffer> _skyboxVertexBuffer;
};

extern SkyBox skyBox;