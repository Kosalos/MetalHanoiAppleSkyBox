#import "Robot.h"
#import "ViewController.h"
#import "Transformations.h"
#import "hanoiBase.h"
#import "hanoiArm.h"
#import "hanoiHand.h"
#import "MMesh.h"
#import "Cube.h"

enum {
	KIND_BASE = 0,
	KIND_ARM,
	KIND_HAND,
    KIND_PICKUP,
};

const char *sName[S_COUNT] = { "Base", "Arm1", "Arm2", "Arm3", "Hand", "Pickup" };

MMesh *globalHanoiBase = nil;
MMesh *globalHanoiArm  = nil;
MMesh *globalHanoiHand = nil;

int numCycles = 20;

@implementation Robot {
    Dpos strt,dest,target;
    int rMoveIndex;
    int bx,by;  // base logical coord
}

-(instancetype)initWithPosition :(int)pbx :(int)pby :(float)x :(float)y
{
    self = [super init];
    if(!self) return nil;
    
    rMoveIndex = 99;
    gripIndex.x = NONE;
    isMoving = false;
    bx = pbx;
    by = pby;
    
    if(!globalHanoiBase) {
        globalHanoiBase = [[MMesh alloc] initWithVertexData:vertex_hanoiBase
                                                vertexCount:VERTEXCOUNT_hanoiBase
                                                  indexData:indice_hanoiBase
                                                 indexCount:INDEXCOUNT_hanoiBase                                     vertexShaderName:@"vertex_main"
                                         fragmentShaderName:@"fragment_main"
                                                textureName:@"p19"];
        globalHanoiArm = [[MMesh alloc] initWithVertexData:vertex_hanoiArm
                                               vertexCount:VERTEXCOUNT_hanoiArm
                                                 indexData:indice_hanoiArm
                                                indexCount:INDEXCOUNT_hanoiArm                                     vertexShaderName:@"vertex_main"
                                        fragmentShaderName:@"fragment_main"
                                               textureName:@"p19"];
        globalHanoiHand = [[MMesh alloc] initWithVertexData:vertex_hanoiHand
                                                vertexCount:VERTEXCOUNT_hanoiHand
                                                  indexData:indice_hanoiHand
                                                 indexCount:INDEXCOUNT_hanoiHand                                     vertexShaderName:@"vertex_main"
                                         fragmentShaderName:@"fragment_main"
                                                textureName:@"p19"];
    }
    
    [self segmentsInit:x:y];
    return self;
}

#pragma mark -

#define RAD(angle) ((angle) / 180.0 * M_PI)

-(void)SegmentDataInit
:(int)segmentIndex
:(int)kind
:(int)parentSegmentIndex
:(float3)pposition
:(float3)pangle
{
    SegmentData &p	= defaultRobotData.data[segmentIndex];
    p.meshKind      = kind;
    p.parentIndex	= parentSegmentIndex;
    p.position		= pposition;
    p.angle         = pangle;
    
    p.angle.x = RAD(p.angle.x);
    p.angle.y = RAD(p.angle.y);
    p.angle.z = RAD(p.angle.z);
}

-(void)segmentsInit:(float)x :(float)y
{
    memset(&defaultRobotData,0,sizeof(RobotData));
    memset(&robotData,0,sizeof(RobotData));
    
    { // Base 0
        float3 p = { 0,0,-2 }; // baseZ };
        p.x = x;
        p.y = y;
        
        float3 a = { 90,180,180 };
        [self SegmentDataInit:S_BASE:KIND_BASE:NONE:p:a];
    }
    
    { // Arm1 1
        float3 p = { 0,1.05, 0.00 };
        float3 a = { 0,0,90};
        [self SegmentDataInit:S_ARM1:KIND_ARM:S_BASE:p:a];
    }

    float a2offset = 13.27;
    { // Arm2 2
        float3 p = { -a2offset,0,0 };
        float3 a = { 0,0,0 }; // { 0,180,180 };
        [self SegmentDataInit:S_ARM2:KIND_ARM:S_ARM1:p:a];
    }

    { // Arm3 3
        float3 p = { -a2offset,0,0 };
        float3 a = { 0,0,50 }; // same
        [self SegmentDataInit:S_ARM3:KIND_ARM:S_ARM2:p:a];
    }

    float hoffset = 13.5;
    { // Hand 4
        float3 p = { -hoffset, 0.00, 0.00 };
        float3 a = { 0,180,0 }; // { 0,180,180 };
        [self SegmentDataInit:S_HAND:KIND_HAND:S_ARM3:p:a];
    }

    { // Pickup 5
        float3 p = { -2.5 , 0.00, 0.00 };
        float3 a = { 0,180,0 };
        [self SegmentDataInit:S_PICKUP:KIND_PICKUP:S_HAND:p:a];
    }

    memcpy(&robotData,&defaultRobotData,sizeof(robotData));
}

float radToDeg(float r)
{
    float d =  r * 180 / M_PI;
    while( d < 0) d += 360;
    while(d >= 360) d -= 360;
    return d;
}

#pragma mark -

void handAngle(RobotData &rd)
{
    float tot = (rd.data[S_ARM1].angle.z -M_PI/2) +
                (rd.data[S_ARM2].angle.z -M_PI) +
                (rd.data[S_ARM3].angle.z -M_PI);

    rd.data[S_HAND].angle.z = tot;
}

#pragma mark -

-(float)distanceToTarget :(RobotData)rd
{
    int parentList[S_COUNT+2];
    int pCount;
 
    // mvm = position of pickup
    pCount = 0;
    parentList[pCount++] = S_PICKUP;
    
    SegmentData &me = rd.data[S_PICKUP];
    int pIndex = me.parentIndex;
    
    while(pIndex != NONE) {
        parentList[pCount++] = pIndex;
        pIndex = rd.data[pIndex].parentIndex;
    }
    
    float4x4 mvm = eyePositionMatrix();
    
    for(int j=pCount-1;j>=0;--j) {
        SegmentData &p = rd.data[parentList[j]];
        mvm = mvm * Translate(p.position.x,p.position.y,p.position.z);
        mvm = mvm * RotationX(p.angle.x);
        mvm = mvm * RotationY(p.angle.y);
        mvm = mvm * RotationZ(p.angle.z);
    }
    
    // targ = position of target
    float4x4 targ = eyePositionMatrix();
    targ = targ * Translate(
                            GX1 + (float)target.x * GXS -GXS/2,
                            GY1 + (float)target.y * GXS -GXS/2,
                            baseZ + (float)target.z * GZS);
    
    float dx = mvm.columns[3].x - targ.columns[3].x;
    float dy = mvm.columns[3].y - targ.columns[3].y;
    float dz = mvm.columns[3].z - targ.columns[3].z;
    
    return sqrtf(dx*dx + dy*dy + dz*dz);
}

#pragma mark -

static float aAmt = 0.0004;

-(void)jointMove
{
    RobotData tmp;
    
    for(int cycles=0;cycles<numCycles;++cycles) {
    
        // base rotation Y axis ----------------------
        tmp = robotData;
        float td = [self distanceToTarget:tmp];
        
        float a1 = robotData.data[S_BASE].angle.y - aAmt;
        tmp.data[S_BASE].angle.y = a1;
        float td1 = [self distanceToTarget:tmp];
        
        float a2 = robotData.data[S_BASE].angle.y + aAmt;
        tmp.data[S_BASE].angle.y = a2;
        float td2 = [self distanceToTarget:tmp];
        
        float bestD = td;
        float bestA = robotData.data[S_BASE].angle.y;
        
        if(td1 < bestD) { bestD = td1;  bestA = a1; }
        if(td2 < bestD) { bestD = td2;  bestA = a2; }
        
        if(bestD == td) {       // locked up
            bestA = td1 < td2 ?  a1 : a2;
        }
        robotData.data[S_BASE].angle.y = bestA;
        
        // arm angles ----------------------------------
        for(int ax = S_ARM1; ax <= S_ARM3;++ax) {
            tmp = robotData;
            handAngle(tmp);
            float td = [self distanceToTarget:tmp];
            
            float a1 = robotData.data[ax].angle.z - aAmt;
            tmp.data[ax].angle.z = a1;
            handAngle(tmp);
            float td1 = [self distanceToTarget:tmp];
            
            float a2 = robotData.data[ax].angle.z + aAmt;
            
            if(ax == S_ARM1 && a2 > 2.5) a2 = 2.5;
            
            tmp.data[ax].angle.z = a2;
            handAngle(tmp);
            float td2 = [self distanceToTarget:tmp];
            
            float bestD = td;
            float bestA = robotData.data[ax].angle.z;
            if(td1 < bestD) { bestD = td1;  bestA = a1; }
            if(td2 < bestD) { bestD = td2;  bestA = a2; }
            robotData.data[ax].angle.z = bestA;
        }

        handAngle(robotData);
    }
}

//            printf("A1 %5.3f  A2 %5.3f  A3 %5.3f  H %5.3f T %5.3f deg  Final %5.3f\n",
//                   robotData.data[S_ARM1].angle.z,
//                   robotData.data[S_ARM2].angle.z,
//                   robotData.data[S_ARM3].angle.z,
//                   robotData.data[S_HAND].angle.z,
//                   radToDeg(tot),
//                   tot+robotData.data[S_HAND].angle.z
//                   );

#pragma mark -

float movementZ = 7;  // how high during transists

-(void)updateRobotTarget
{
    float td = [self distanceToTarget:robotData];
    if(td > .1) return;
    
    ++rMoveIndex;

    switch(rMoveIndex) {
        case 1 :
            target.z = strt.z;
            break;
            
        case 2 :        // at Start; grab disk, move above Start
            gripIndex = strt; // disk will follow robot
            diskData.cell[strt.x][strt.y][strt.z].gripped = true;
            target.z += movementZ;   // move to above source column
            break;

        case 3 :        // above Start, move to above Desination
            target = dest;
            target.z += movementZ;
            break;

        case 4 :        // above dest, move to dest
            target = dest;
            break;

        case 5 :        // reached Dest, release disk
            {
                gripIndex.x = NONE;
                CellData &s = diskData.cell[strt.x][strt.y][strt.z];
                CellData &d = diskData.cell[dest.x][dest.y][dest.z];
                
                d.color = s.color;
                d.status = STATUS_IDLE;
                d.gripped = false;
                
                s.status = STATUS_EMPTY;
                s.gripped = false;
            }
            break;

        case 6 :        // move to above dest
            target.z += 5;
            break;
            
        default :
            isMoving = false;
            break;
    }
}

#pragma mark -


const char *sCode[] = { "-","*","S","D" };
const char *gCode[] = { "-","G" };

char str[4][32];

void cd(int x,int y,int z)
{
    CellData c = diskData.cell[x][y][z];
    sprintf(str[x],"%s%s  ",sCode[c.status],gCode[c.gripped]);
}

void cellDebug()
{
    for(int z=MAX_LEVELS-1;z>=0;--z) {
        printf("Level %d\n",z);
        for(int y=0;y<=GXCOUNT;++y) {
            for(int x=0;x<4;++x)
                cd(x,y,z);
            printf("%s %s %s %s\n",str[0],str[1],str[2],str[3]);
        }
    }
}

#pragma mark -

-(void)update
{
    if(!isMoving) {
        strt = diskData.randomSource(bx,by);
        dest = diskData.randomDestination(bx,by);
        
//        printf("S %2d %2d %2d stat %d   D %2d %2d %2d stat %d\n",
//               strt.x,strt.y,strt.z,
//               diskData.cell[strt.x][strt.y][strt.z].status,
//               dest.x,dest.y,dest.z,
//               diskData.cell[dest.x][dest.y][dest.z].status
//               );
        
//        printf("--------------------\nStrt: %d,%d,%d\n",strt.x,strt.y,strt.z);
//        printf("Dest: %d,%d,%d\n",dest.x,dest.y,dest.z);
//        cellDebug();
        
        target = strt;  // above strt
        target.z += 5;
        
        rMoveIndex = 0;
        isMoving = true;
    }
    
    if(isMoving) {
        [self jointMove];
        [self updateRobotTarget];
    }
}

#pragma mark -


-(void)draw
{
    int parentList[S_COUNT+2];
    int pCount;

    for(int i=0;i<S_COUNT;++i) {
		pCount = 0;
		parentList[pCount++] = i;

		SegmentData &me = robotData.data[i];
		int pIndex = me.parentIndex;
        
		while(pIndex != NONE) {
			parentList[pCount++] = pIndex;
			pIndex = robotData.data[pIndex].parentIndex;
		}

        float4x4 mvm = eyePositionMatrix();
        
        for(int j=pCount-1;j>=0;--j) {
			SegmentData &p = robotData.data[parentList[j]];
            
            mvm = mvm * Translate(p.position.x,p.position.y,p.position.z);
            mvm = mvm * RotationX(p.angle.x);
            mvm = mvm * RotationY(p.angle.y);
            mvm = mvm * RotationZ(p.angle.z);
        }
        
 //       globalLight[0].direction = { 1,1,0 };
   //     globalLight[1].direction = { 2,2,0 };

//        globalLight[0].direction = gLight[0];
//        globalLight[1].direction = gLight[1];

        switch(me.meshKind) {
            case KIND_BASE :   [globalHanoiBase draw:mvm:1];    break;
            case KIND_ARM  :   [globalHanoiArm  draw:mvm:1];    break;
            case KIND_HAND:    [globalHanoiHand draw:mvm:1];    break;
        }

        if(me.meshKind == KIND_PICKUP) {
            if(gripIndex.x != NONE) {
                cube->colorData = diskData.cell[gripIndex.x][gripIndex.y][gripIndex.z].color;
//                globalLight[0].direction = { 0,0,0 };
//                globalLight[1].direction = { 0,0,0 };
                
                //[cube draw:mvm:1];

                float4x4 cc = Identity(); //eyePositionMatrix();
                cc = cc * Translate(mvm.columns[3].x,mvm.columns[3].y,mvm.columns[3].z);
                cc = cc * RotationY(-robotData.data[S_BASE].angle.y);
                cc = cc * RotationX(-robotData.data[S_BASE].angle.x);
                [cube draw:cc:1];
            }
        }
    }
}

@end
