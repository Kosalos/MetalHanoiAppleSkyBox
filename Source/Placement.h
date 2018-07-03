#import <UIKit/UIKit.h>

@interface PlacementView : UIView

@property (nonatomic,retain) IBOutlet UIButton  *hideButton;

@property (nonatomic,retain) IBOutlet UIStepper *indexStepper;
@property (nonatomic,retain) IBOutlet UISlider  *pxSlider;
@property (nonatomic,retain) IBOutlet UISlider  *pySlider;
@property (nonatomic,retain) IBOutlet UISlider  *pzSlider;
@property (nonatomic,retain) IBOutlet UISlider  *axSlider;
@property (nonatomic,retain) IBOutlet UISlider  *aySlider;
@property (nonatomic,retain) IBOutlet UISlider  *azSlider;
@property (nonatomic,retain) IBOutlet UILabel   *description;

-(IBAction)stepperPressed :(UIStepper *)sender;
-(IBAction)sliderPressed :(UISlider *)sender;
-(IBAction)buttonPressed :(UIButton *)sender;

-(void)appear;

@end
