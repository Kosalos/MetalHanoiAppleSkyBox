#include <stdlib.h>
#import "World.h"
#import "Cube.h"
#import "Renderer.h"
#import "ViewController.h"
#import "Transformations.h"

float GXS = 2;
float GZS = 1.01;    // cube height

float GX1 = -(GXS * GXCOUNT)/2;
float GY1 = -(GXS * GXCOUNT)/2;

float gridZ = 0;
float baseZ = gridZ + 0.5;

DiskData diskData;

float random01() {  return (float)(rand() & 1023)/1024.0; }
float random51() {  return 0.5 + random01() * 0.5; }

DiskData::DiskData()
{
    reset();
}

void DiskData::setStatus(int x,int y,int z,int status)
{
    if(x < 0 || x > GXCOUNT || y < 0 || y > GXCOUNT || z < 0 || z >= MAX_LEVELS) {
        printf("Bad index %d %d %d\n",x,y,z);
        exit(0);
    }
    
    cell[x][y][z].status = status;
    if(status == STATUS_EMPTY)
        cell[x][y][z].gripped = false;
}

void DiskData::setStatus(Dpos p,int status)
{
    setStatus(p.x,p.y,p.z,status);
}

int DiskData::getStatus(int x,int y,int z)
{
    if(x < 0 || x > GXCOUNT || y < 0 || y > GXCOUNT || z < 0 || z >= MAX_LEVELS) {
        printf("Bad index %d %d %d\n",x,y,z);
        exit(0);
    }
    
    return cell[x][y][z].status;
}

int DiskData::getStatus(Dpos p)
{
    return getStatus(p.x,p.y,p.z);
}

#pragma mark -

void DiskData::reset()
{
    for(int x=0;x<=GXCOUNT;++x)
        for(int y=0;y<=GYCOUNT;++y)
            for(int z=0;z<MAX_LEVELS;++z)
                setStatus(x,y,z,STATUS_EMPTY);
    
    bool okay;
    int x,y,z;
    
    for(int i=0;i<NUM_DISK;++i) {
        for(;;) {
            okay = false;
            x = 1 + (rand() % GXCOUNT);
            y = 1 + (rand() % GXCOUNT);
            
            for(z=0;z<MAX_LEVELS;++z) {
                int status = getStatus(x,y,z);
                if(status == STATUS_EMPTY) {
                    CellData &c = cell[x][y][z];
                    c.status = STATUS_IDLE;
                    c.color.diffuseColor.x = random51();
                    c.color.diffuseColor.y = random51();
                    c.color.diffuseColor.z = random51();
                    c.color.alpha = 1;
                    
                    okay = true;
                    break;
                }
            }
            
            if(okay) break;
        }
    }
}

#pragma mark -

bool closeBy(Dpos p,int x,int y)
{
    float dist = hypotf(p.x-x, p.y-y);
    return dist < 3;
}

bool DiskData::columnIsBusy(Dpos p)
{
    int status;
    
    for(p.z=0;p.z<MAX_LEVELS;++p.z) {
        status = getStatus(p);
        if(status == STATUS_START || status == STATUS_DEST)
            return true;
    }
    
    return false;
}

bool DiskData::cellBelowIdle(Dpos p)
{
    if(p.z == 0) return true;
    
    --p.z;
    int status = getStatus(p);
    
    return status == STATUS_IDLE;
}


#pragma mark -

Dpos DiskData::randomSource(int basex,int basey)
{
    Dpos pos;
    int status;
    
    for(;;) {
        pos.x = 1 + (rand() % GXCOUNT);
        pos.y = 1 + (rand() % GXCOUNT);
        
        if(!columnIsBusy(pos) && !closeBy(pos,basex,basey)) {
            for(pos.z=MAX_LEVELS-1;pos.z>=0;--pos.z) {
                status = getStatus(pos);
                if(status == STATUS_EMPTY) continue;
                
                if(status == STATUS_IDLE) {
                    setStatus(pos,STATUS_START);
                    return pos;
                }
                
                break;
            }
        }
    }
}

Dpos DiskData::randomDestination(int basex,int basey)
{
    Dpos pos;
    int status;
    
    for(;;) {
        pos.x = 1 + (rand() % GXCOUNT);
        pos.y = 1 + (rand() % GXCOUNT);

        if(closeBy(pos,basex,basey)) {
            pos.z = 0;
            while(pos.z < MAX_LEVELS) {
                status = getStatus(pos);
                if(status == STATUS_EMPTY && cellBelowIdle(pos)) {
                    setStatus(pos,STATUS_DEST);
                    return pos;
                }
                
                ++pos.z;
            }
        }
    }
}

#pragma mark -

void DiskData::drawCell(int x,int y,int z)
{
    int status = getStatus(x,y,z);
    if(status == STATUS_EMPTY) return;
    if(status == STATUS_DEST) return;
    if(status == STATUS_START && cell[x][y][z].gripped) return;
    
    float4x4 mvm = eyePositionMatrix();
    
    mvm = mvm * Translate(GX1 + x * GXS -GXS/2, GY1 + y * GXS -GXS/2, baseZ + z * GZS);
    
    cube->colorData = cell[x][y][z].color;
    
    [cube draw:mvm:1];
}

void DiskData::draw()
{
    for(int x=1;x<=GXCOUNT;++x)
        for(int y=1;y<=GYCOUNT;++y)
            for(int z=0;z<MAX_LEVELS;++z) 
                drawCell(x,y,z);
}
