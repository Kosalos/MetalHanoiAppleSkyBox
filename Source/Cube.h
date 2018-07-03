#import <UIKit/UIKit.h>
#import "Shared.h"

@interface Cube : NSObject {
    @public ColorData colorData;
}

-(void)draw :(float4x4)modelView :(float)scale;

@end

extern Cube *cube;