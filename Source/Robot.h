#import <UIKit/UIKit.h>
#import "Shared.h"
#import "World.h"

enum {
	S_BASE = 0,
	S_ARM1,
    S_ARM2,
    S_ARM3,
	S_HAND,
    S_PICKUP,
	S_COUNT,
    
    X=0,Y,Z,
};

typedef struct
{
    int meshKind;
    int parentIndex;
    float3 position;
    float3 angle;
} SegmentData;

typedef struct {
    SegmentData data[S_COUNT];
} RobotData;

@interface Robot : NSObject {
    @public RobotData robotData,defaultRobotData;
    Dpos gripIndex;
    bool isMoving;
}

-(instancetype)initWithPosition:(int)bx :(int)by :(float)x :(float)y;
-(void)draw;
-(void)update;

@end

extern int numCycles;
extern const char *sName[];
