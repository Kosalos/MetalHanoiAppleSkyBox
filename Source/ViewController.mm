#import "ViewController.h"
#import "Renderer.h"
#import "Transformations.h"
#import "Cube.h"
#import "MMesh.h"
#import "Robot.h"
#import "Grid.h"

float3 eye;
float2 eyeAngle;
float4x4 globalProjectionMatrix;
float3 gLight[2];

float AA = .6;
float SS = 0.1;

Light globalLight[NUM_LIGHT] = {
    {
        true,
        { .1,.1,0 },  // { 0.13, 0.72, 0.68 },   // direction
        { AA,AA,AA },            // ambientColor
        { AA,AA,AA },      // diffuseColor
        { SS,SS,SS },             // specularColor
        1000
    },
    {
        false,
        { .1,.1,.5 },  // { 0.13, 0.72, 0.68 },   // direction
        { AA,AA,AA },            // ambientColor
        { AA,AA,AA },      // diffuseColor
        { SS,SS,SS },             // specularColor
        1000
    },
    
};

void abort(const char *filename,int line)
{
    printf("****\nAbort at %s, line %d\n",filename,line);
    exit(0);
}

@interface ViewController ()
@property (nonatomic, strong) CADisplayLink *redrawTimer;
@property (nonatomic, assign) NSTimeInterval lastMooTime;
@property (nonatomic, assign) CGPoint angularVelocity;
@property (nonatomic, assign) CGPoint angle;
@property (nonatomic, assign) NSTimeInterval lastFrameTime;
@end

Robot *robot[4];

@implementation ViewController

@synthesize manualButton,placementButton;


-(BOOL)prefersStatusBarHidden{
    return YES;
}

-(void)dealloc
{
    [_redrawTimer invalidate];
}

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    srand((unsigned int)clock());
    
    renderer = [[Renderer alloc] initWithView:self.view];
    
    float rOffset = 2;
    robot[0] = [[Robot alloc] initWithPosition:1:1:             GX1-rOffset:GY1-rOffset];
    robot[1] = [[Robot alloc] initWithPosition:1:GXCOUNT:       GX1-rOffset:GY1+GXS*GXCOUNT+rOffset];
    robot[2] = [[Robot alloc] initWithPosition:GXCOUNT:GXCOUNT: GX1+GXS*GXCOUNT+rOffset:GY1+GXS*GXCOUNT+rOffset];
    robot[3] = [[Robot alloc] initWithPosition:GXCOUNT:1:       GX1+GXS*GXCOUNT+rOffset:GY1-rOffset];
    
    cube = [[Cube alloc]init];
    grid = [[Grid alloc]init];

    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self.view addGestureRecognizer:pinchRecognizer];
    
    const float near = 0.1;
    const float far = 1000;
    const float aspect = self.view.bounds.size.width / self.view.bounds.size.height;
    globalProjectionMatrix = PerspectiveProjection(aspect, DEGREES_TO_RADIANS(75), near, far);

    [self initialAngle];

    _placementV.hidden = YES;
    
    [self.view setOpaque:YES];
    [self.view setBackgroundColor:nil];
    [self.view setContentScaleFactor:[UIScreen mainScreen].scale];
}

-(void)reset
{
    diskData.reset();
    
    for(int i=0;i<4;++i) {
        robot[i]->gripIndex.x = NONE;
        robot[i]->isMoving = false;
    }
}

-(void)pinch:(UIPinchGestureRecognizer *)recognizer
{
    CGFloat s = recognizer.scale;
    s = 1 + (s-1)/30.0;
    
    eye.z /= s;
    if(eye.z > -2) eye.z = -2;
    if(eye.z < -800) eye.z = -800;
}

-(IBAction)buttonPressed :(UIButton *)sender
{
    CGRect bd = [self.view bounds];

    if(sender == placementButton) {
        const int xs = 560;
        const int ys = 190;
        [_placementV setFrame:CGRectMake(bd.size.width-xs,bd.size.height-ys,xs,ys)];
        
        [_placementV appear];
    }
}

-(IBAction)sliderPressed :(UISlider *)sender
{
    numCycles = (int)sender.value;
}


-(void)initialAngle
{
    eyeAngle.x = 8.1;
    eyeAngle.y = 9.43;
    
    eye.x = 0;
    eye.y = 0;
    eye.z = -24;
}

float4x4 eyePositionMatrix()
{
    float4x4 mvm = Translate(eye.x,eye.y,eye.z);
    if(eyeAngle.x) mvm = mvm * RotationX(eyeAngle.x);
    if(eyeAngle.y) mvm = mvm * RotationZ(eyeAngle.y);

    return mvm;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.redrawTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(redrawTimerDidFire:)];
    [self.redrawTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.redrawTimer invalidate];
    self.redrawTimer = nil;
}

-(void)redrawTimerDidFire:(CADisplayLink *)sender
{
    [self redraw];
}

#pragma mark -

CGPoint lastPt;
bool touching = false;
float dx,dy;

-(void)touchesBegan :(NSSet *)touches withEvent :(UIEvent *)event
{
 //   if(_placementV.hidden == NO) return;
    
    NSArray *a = [touches allObjects];
    for(int i=0;i < (int)touches.count;++i) {
        UITouch *u1 = [a objectAtIndex:i];
        lastPt = [u1 locationInView:[u1 view]];
        
        if(lastPt.x < 50 && lastPt.y < 50) {
            [self reset];
            return;
        }
        
        touching = true;
    }
}

#define DEN 100.0

-(void)touchesMoved :(NSSet *)touches withEvent :(UIEvent *)event
{
    if(!touching) return;
    
    NSArray *a = [touches allObjects];
    for(int i=0;i < (int)touches.count;++i) {
        UITouch *u1 = [a objectAtIndex:i];
        CGPoint pt = [u1 locationInView:[u1 view]];
        
        dx = (lastPt.x - pt.x);
        dy = (lastPt.y - pt.y);
        
        eyeAngle.x -= dy/DEN;
        eyeAngle.y -= dx/DEN;
        
       // printf("Eye %f %f\n",eyeAngle.x,eyeAngle.y);
        
        lastPt = pt;
    }
}

-(void)touchesEnded :(NSSet *)touches withEvent :(UIEvent *)event
{
    touching = false;
}

#pragma mark -

-(void)redraw
{
    static float aa;
    float DD = 3;
    gLight[0].x = sinf(aa) * DD;
    gLight[0].y = cosf(aa) * DD;
    gLight[0].z = cosf(aa/2) * DD;
    
    gLight[1].x = -cosf(aa * 2) * DD;
    gLight[1].y = sinf(aa * 2) * DD;
    gLight[1].z = cosf(aa/2) * DD;
    aa += 0.003;

    [renderer startFrame];
    
    globalLight[0].direction = gLight[0];
    globalLight[1].direction = gLight[1];
    
    for(int i=0;i<4;++i) {
        [robot[i] update];
        [robot[i] draw];
    }
    
    float4x4 mvm = eyePositionMatrix();
    mvm = mvm * Translate(0,0,gridZ);
    [grid update:mvm:1];
    [grid draw];
    
//    globalLight[0].direction = { 0,0,0 };
//    globalLight[1].direction = { 0,0,0 };

    diskData.draw();
    
    [renderer endFrame];
    
   // eyeAngle.y  += 0.001;
}

@end

/*
 
 http://www.yelp.com/biz/mikes-auto-tops-and-upholstery-mission-viejo
 http://www.yelp.com/biz/willys-auto-upholstery-laguna-niguel
 http://www.yelp.com/biz/kennys-auto-upholstery-mission-viejo-2
 
*/
//Kee 330   // http://www.gomiata.com/keeautopmxmi11.html
// sierra 439 // http://www.gomiata.com/rosoto.html
// robbins 520
// gahh 534

// $390 http://www.topsonline.com/model/Convertible_Tops_And_Accessories/Mazda/1998_thru_2005_Mazda_Miata_MX5_And_MX5_Eunos.html

// do yourself $300
// https://www.convertibletopguys.com/convertible/746/1999-05-Mazda-Miata-Miata-MX-5-Shinsen-quot;Easy-Install-quot;-One-Piece-Convertible-Tops

// http://www.prestigemobileupholstery.com/convertible_top_install  come to you / anaheim
// http://www.aaaconvertible.com/contact.html                       costa mesa 17th
// http://www.ocroyalupholstery.com/g allery/auto-upholstery.aspx  laguna beach
