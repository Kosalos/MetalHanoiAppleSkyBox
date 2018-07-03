#import <UIKit/UIKit.h>
#import "Shared.h"
#import "World.h"

@interface Grid : NSObject {
    @public ColorData colorData;
}

-(void)update:(float4x4)modelView :(float)scale;
-(void)draw;

@end

extern Grid *grid;
