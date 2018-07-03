#pragma once
#import "Shared.h"

enum {
    MAX_LEVELS = 6,
    GXCOUNT = 10,
    GYCOUNT = GXCOUNT,

    NONE = -1,
    NUM_DISK = 80,
    
    STATUS_EMPTY = 0,
    STATUS_IDLE,
    STATUS_START,
    STATUS_DEST
};

typedef struct {
    int x,y,z;
} Dpos;

typedef struct {
    int status;
    bool gripped;
    ColorData color;
} CellData;

class DiskData
{
public:
    DiskData();
    CellData cell[GXCOUNT+1][GXCOUNT+1][MAX_LEVELS+1];
    
    void reset();
    void draw();
    Dpos randomSource(int basex,int basey);
    Dpos randomDestination(int basex,int basey);
    
private:
    void drawIndex(int index);
    void drawCell(int x,int y,int z);
    
    void setStatus(int x,int y,int z,int status);
    void setStatus(Dpos p,int status);
    int  getStatus(int x,int y,int z);
    int  getStatus(Dpos p);
    bool columnIsBusy(Dpos p);
    bool cellBelowIdle(Dpos p);
};

extern float GX1;   // grid position
extern float GY1;

extern float GXS;   // grid cell size
extern float GZS;   // cube Z axis height hop

extern float gridZ;
extern float baseZ;
extern DiskData diskData;

