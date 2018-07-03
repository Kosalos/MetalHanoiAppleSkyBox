#import "Shared.h"
#import "Placement.h"
#import "Robot.h"

@implementation PlacementView

@synthesize hideButton;
@synthesize indexStepper,pxSlider,pySlider,pzSlider;
@synthesize axSlider,aySlider,azSlider,description;

int ssIndex = 0;

-(void)appear
{
    indexStepper.value = ssIndex;  // from previous run
    [self stepperPressed:indexStepper];
    
    self.hidden = FALSE;
}

-(IBAction)buttonPressed :(UIButton *)sender
{
    if(sender == hideButton)
        self.hidden = YES;
}

-(IBAction)stepperPressed :(UIStepper *)sender
{
    ssIndex = (int)sender.value;
    printf("index %d\n",ssIndex);
    
    description.text = [NSString stringWithFormat:@"%s",sName[ssIndex]];
}

float KK = 2;

int DEG(float a)
{
    return (int)(180.0 * a / M_PI);
}

-(IBAction)sliderPressed :(UISlider *)sender
{
//    SegmentData *p	= &robot[0]->robotData.data[ssIndex];
//    
//    if(sender == pxSlider) p->position.x = sender.value / KK;
//    if(sender == pySlider) p->position.y = sender.value / KK;
//    if(sender == pzSlider) p->position.z = sender.value / KK;
//    
//    float angle = sender.value / 2;
//    if(sender == axSlider) p->angle.x = angle;
//    if(sender == aySlider) p->angle.y = angle;
//    if(sender == azSlider) p->angle.z = angle;
    
//    printf("\n{ // %s %d\n",sName[ssIndex],ssIndex);
//    printf("float3 p = { %5.2f,%5.2f,%5.2f };\n",p->position.x,p->position.y,p->position.z);
//    printf("float3 a = { %d,%d,%d };\n",DEG(p->angle.x),DEG(p->angle.y),DEG(p->angle.z));
}

@end
