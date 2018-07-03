#import <UIKit/UIKit.h>
#import "Renderer.h"
#import "Shared.h"
#import "Placement.h"
#import "MMesh.h"

@interface ViewController : UIViewController <UIGestureRecognizerDelegate> {
}

@property (nonatomic,retain) IBOutlet UIButton  *manualButton;
@property (nonatomic,retain) IBOutlet UIButton  *placementButton;

@property (nonatomic,retain) IBOutlet PlacementView *placementV;

@property (nonatomic,retain) IBOutlet UISlider  *cycleSlider;

-(IBAction)buttonPressed :(UIButton *)sender;
-(IBAction)sliderPressed :(UISlider *)sender;

@end

extern float4x4 eyePositionMatrix();
extern float4x4 globalProjectionMatrix;

extern float3 eye;
extern float2 eyeAngle;
extern float3 gLight[2];


extern Light globalLight[NUM_LIGHT];

void abort(const char *filename,int line);

#define ABORT abort(__FILE__,__LINE__)

extern bool touching;
