#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@interface MetalView : UIView

@property (nonatomic, readonly) CAMetalLayer *metalLayer;

@end
