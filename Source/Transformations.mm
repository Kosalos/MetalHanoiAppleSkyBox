#import "Transformations.h"

float4x4 Identity()
{
    float4 X = { 1, 0, 0, 0 };
    float4 Y = { 0, 1, 0, 0 };
    float4 Z = { 0, 0, 1, 0 };
    float4 W = { 0, 0, 0, 1 };
    
    float4x4 identity(X, Y, Z, W);
    
    return identity;
}

//static float3 X_AXIS = { 1,0,0 };
//static float3 Y_AXIS = { 0,1,0 };
//static float3 Z_AXIS = { 0,0,1 };

float4x4 Rotation(float3 axis, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    
    float4 X;
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
    X.y = axis.x * axis.y * (1 - c) - axis.z*s;
    X.z = axis.x * axis.z * (1 - c) + axis.y * s;
    X.w = 0.0;
    
    float4 Y;
    Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
    Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
    Y.w = 0.0;
    
    float4 Z;
    Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
    Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
    Z.w = 0.0;
    
    float4 W;
    W.x = 0.0;
    W.y = 0.0;
    W.z = 0.0;
    W.w = 1.0;
    
    float4x4 mat = { X, Y, Z, W };
    return mat;
}

float4x4 RotationX(float angle)
{
//    return Rotation(X_AXIS,angle);
    
    float c = cosf(angle);
    float s = sinf(angle);
    float4x4 mat = Identity();
    
    mat.columns[1].y = c;
    mat.columns[2].z = c;
    mat.columns[2].y = s;
    mat.columns[1].z = -s;
    
    return mat;
}

float4x4 RotationY(float angle)
{
//    return Rotation(Y_AXIS,angle);

    float c = cosf(angle);
    float s = sinf(angle);
    float4x4 mat = Identity();
    
    mat.columns[0].x = c;
    mat.columns[2].z = c;
    mat.columns[0].z = s;
    mat.columns[2].x = -s;
    
    return mat;
}

float4x4 RotationZ(float angle)
{
//    return Rotation(Z_AXIS,angle);

    float c = cosf(angle);
    float s = sinf(angle);
    float4x4 mat = Identity();
    
    mat.columns[0].x = c;
    mat.columns[1].y = c;
    mat.columns[1].x = s;
    mat.columns[0].y = -s;
    
    return mat;
}

float4x4 PerspectiveProjection(float aspect, float fovy, float near, float far)
{
    float yScale = 1 / tan(fovy * 0.5);
    float xScale = yScale / aspect;
    float zRange = far - near;
    float zScale = -(far + near) / zRange;
    float wzScale = -2 * far * near / zRange;
    
    float4 P = { xScale, 0, 0, 0 };
    float4 Q = { 0, yScale, 0, 0 };
    float4 R = { 0, 0, zScale, -1 };
    float4 S = { 0, 0, wzScale, 0 };
    
    float4x4 mat = { P, Q, R, S };
    return mat;
}

float3x3 UpperLeft3x3(const float4x4 &mat4x4)
{
    return float3x3(mat4x4.columns[0].xyz, mat4x4.columns[1].xyz, mat4x4.columns[2].xyz);
}

float4x4 Translate(float dx,float dy,float dz)
{
    float4x4 mat = Identity();
    
    mat.columns[3].x = dx;
    mat.columns[3].y = dy;
    mat.columns[3].z = dz;
    
    return mat;
}
