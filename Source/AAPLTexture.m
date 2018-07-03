/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Texture Loading classes for Metal. Includes examples of how to load a 2D, and Cubemap textures.
  
 */

#import "AAPLTexture.h"

@interface AAPLTexture ()
@property (readwrite) id <MTLTexture> texture;
@property (readwrite) uint32_t width;
@property (readwrite) uint32_t height;
@property (readwrite) uint32_t pixelFormat;
@property (readwrite) uint32_t target;
@property (readwrite) BOOL hasAlpha;
@end

@implementation AAPLTexture

- (instancetype)initWithResourceName:(NSString *)name extension:(NSString *)ext
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
    if (!path)
        return nil;
    
    self = [super init];
    if (self) {
        _pathToTextureFile = path;
        _width = _height = 0;
        _depth = 1;
    }
    return self;
}

- (BOOL)loadIntoTextureWithDevice:(id <MTLDevice>)device
{
    // to be implemented by subclasses
    assert(0);
}
@end

@implementation AAPLTexture2D

// assumes png file
- (BOOL)loadIntoTextureWithDevice:(id <MTLDevice>)device
{
    UIImage *image = [UIImage imageWithContentsOfFile:self.pathToTextureFile];
    if (!image)
        return NO;
    
    self.width = (uint32_t)CGImageGetWidth(image.CGImage);
    self.height = (uint32_t)CGImageGetHeight(image.CGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate( NULL, self.width, self.height, 8, 4 * self.width, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast );
    CGContextDrawImage( context, CGRectMake( 0, 0, self.width, self.height ), image.CGImage );
    
    MTLTextureDescriptor *texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                     width:self.width
                                                                                    height:self.height
                                                                                 mipmapped:NO];
    self.target = texDesc.textureType;
    self.texture = [device newTextureWithDescriptor:texDesc];
    if (!self.texture)
        return NO;
    
    [self.texture replaceRegion:MTLRegionMake2D(0, 0, self.width, self.height)
                    mipmapLevel:0
                      withBytes:CGBitmapContextGetData(context)
                    bytesPerRow:4 * self.width];
    
    CGColorSpaceRelease( colorSpace );
    CGContextRelease(context);
    
    return YES;
}

@end

@implementation AAPLTextureCubeMap

// assumes png file
- (BOOL)loadIntoTextureWithDevice:(id <MTLDevice>)device
{
    UIImage *image = [UIImage imageWithContentsOfFile:self.pathToTextureFile];
    if (!image)
        return NO;
    
    self.width = (uint32_t)CGImageGetWidth(image.CGImage);
    self.height = (uint32_t)CGImageGetHeight(image.CGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate( NULL, self.width, self.height, 8, 4 * self.width, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast );
    CGContextDrawImage( context, CGRectMake( 0, 0, self.width, self.height ), image.CGImage );
    
    unsigned Npixels = self.width * self.width;
    MTLTextureDescriptor *texDesc = [MTLTextureDescriptor textureCubeDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm size:self.width mipmapped:NO];
    self.target = texDesc.textureType;
    self.texture = [device newTextureWithDescriptor:texDesc];
    if (!self.texture)
        return NO;
    
    void *imageData = CGBitmapContextGetData(context);
    for (int i = 0; i < 6; i++)
    {
        [self.texture replaceRegion:MTLRegionMake2D(0, 0,self.width, self.width)
                        mipmapLevel:0
                              slice:i
                          withBytes:imageData + (i * Npixels * 4)
                        bytesPerRow:4 * self.width
                      bytesPerImage:Npixels * 4];
    }
    
    CGColorSpaceRelease( colorSpace );
    CGContextRelease(context);
    
    return YES;
}

// ===================================================================

-(uint8_t *)dataForImage:(UIImage *)image
{
    CGImageRef imageRef = [image CGImage];
    
    // Create a suitable bitmap context for extracting the bits of the image
    const NSUInteger width = CGImageGetWidth(imageRef);
    const NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8_t *rawData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    const NSUInteger bytesPerPixel = 4;
    const NSUInteger bytesPerRow = bytesPerPixel * width;
    const NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    return rawData;
}

-(bool)loadIntoTextureWithPngs:(NSArray *)names device:(id<MTLDevice>)device
{
    NSString *path = [[NSBundle mainBundle] pathForResource:names[0] ofType:@""];
    if(!path) return false;

    UIImage *image1 = [UIImage imageWithContentsOfFile:path];
    if(!image1) {
        printf("Error loading %s\n",path.UTF8String);
        exit(0);
    }
    
    const CGFloat cubeSize = image1.size.width * image1.scale;
    const NSUInteger bytesPerPixel = 4;
    const NSUInteger bytesPerRow = bytesPerPixel * cubeSize;
    const NSUInteger bytesPerImage = bytesPerRow * cubeSize;
    
    MTLRegion region = MTLRegionMake2D(0, 0, cubeSize, cubeSize);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor textureCubeDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                    size:cubeSize
                                                                                               mipmapped:NO];
    
    self.texture = [device newTextureWithDescriptor:textureDescriptor];
    
    for (size_t slice = 0; slice < 6; ++slice) {
        NSString *imageName = names[slice];
        UIImage *image = [UIImage imageNamed:imageName];
        
        if(!image) {
            printf("Error loading %s\n",imageName.UTF8String);
            exit(0);
        }

        uint8_t *imageData = [self dataForImage:image];
        
        NSAssert(image.size.width == cubeSize && image.size.height == cubeSize, @"Cube map images must be square and uniformly-sized");
        
        [self.texture replaceRegion:region
                   mipmapLevel:0
                         slice:slice
                     withBytes:imageData
                   bytesPerRow:bytesPerRow
                 bytesPerImage:bytesPerImage];
        free(imageData);
    }
    
    return true;
}

@end
