//
//  shaders.h
//  SunnyTelescope
//
//  Created by sunny on 2017/4/14.
//  Copyright © 2017年 com.sunnyoptical. All rights reserved.
//

#ifndef shaders_h
#define shaders_h

char *const vertexShaderAsteroid = "attribute vec4 position;\
attribute vec2 TexCoordIn;\
varying vec2 TexCoordOut;\
\
void main()\
{\
    gl_Position = position;\
    TexCoordOut = position.xy;\
}";

char *const vertexShaderNormal = "attribute vec4 position;\
attribute vec2 TexCoordIn;\
varying vec2 TexCoordOut;\
uniform mat4 modelViewProjectionMatrix;\
\
void main()\
{\
gl_Position = modelViewProjectionMatrix * position;\
TexCoordOut = TexCoordIn;\
\
}";

char *const yuvFragmentShaderAsteroid = "precision mediump float;\
\
varying highp vec2 TexCoordOut;\
uniform sampler2D SamplerY;\
uniform sampler2D SamplerU;\
uniform sampler2D SamplerV;\
\
uniform mediump float scale;\
uniform mediump float aspect;\
uniform mediump float ramda;\
uniform mediump float feta;\
\
vec2 directionToTexturePos(vec2 coords)\
{\
    highp float PI = 3.1415926535897932384626433832795;\
\
    float p = length(coords);\
    float c = 2.0 * atan( p );\
\
    float lat = asin(cos(c)*sin(PI * ramda)+coords.y*sin(c)*cos(PI * ramda)/p);\
    float lon = feta * PI + atan(coords.x*sin(c),(p*cos(PI * ramda)*cos(c)-coords.y*sin(PI * ramda)*sin(c)));\
\
    return vec2( mod(lon/(2.0*PI), 1.0), (0.5-lat/PI) );\
}\
\
void main()\
{\
    mediump vec3 yuv;\
    lowp vec3 rgb;\
    mediump vec2 scaledCoords;\
    mediump vec2 texCoords;\
\
    scaledCoords = TexCoordOut * vec2(scale * aspect, scale);\
    texCoords = directionToTexturePos(scaledCoords);\
\
    yuv.x = texture2D(SamplerY, texCoords).r;\
    yuv.y = texture2D(SamplerU, texCoords).r - 0.5;\
    yuv.z = texture2D(SamplerV, texCoords).r - 0.5;\
\
    rgb = mat3( 1,       1,         1,\
               0,       -0.39465,  2.03211,\
               1.13983, -0.58060,  0) * yuv;\
\
    gl_FragColor = vec4(rgb, 1.0);\
}";

char *const yuvFragmentShaderNormal = "precision mediump float;\
\
varying highp vec2 TexCoordOut;\
uniform sampler2D SamplerY;\
uniform sampler2D SamplerU;\
uniform sampler2D SamplerV;\
\
void main()\
{\
    mediump vec3 yuv;\
    lowp vec3 rgb;\
\
    yuv.x = texture2D(SamplerY, TexCoordOut).r;\
    yuv.y = texture2D(SamplerU, TexCoordOut).r - 0.5;\
    yuv.z = texture2D(SamplerV, TexCoordOut).r - 0.5;\
\
    rgb = mat3( 1,       1,         1,\
               0,       -0.39465,  2.03211,\
               1.13983, -0.58060,  0) * yuv;\
\
    gl_FragColor = vec4(rgb, 1.0);\
}";

char *const rgbFragmentShaderAsteroid = "precision mediump float;\
\
varying highp vec2 TexCoordOut;\
uniform sampler2D s_texture;\
\
uniform mediump float scale;\
uniform mediump float aspect;\
uniform mediump float ramda;\
uniform mediump float feta;\
\
vec2 directionToTexturePos(vec2 coords)\
{\
    highp float PI = 3.1415926535897932384626433832795;\
\
    float p = length(coords);\
    float c = 2.0 * atan( p );\
\
    float lat = asin(cos(c)*sin(PI * ramda)+coords.y*sin(c)*cos(PI * ramda)/p);\
    float lon = feta * PI + atan(coords.x*sin(c),(p*cos(PI * ramda)*cos(c)-coords.y*sin(PI * ramda)*sin(c)));\
\
    return vec2( mod(lon/(2.0*PI), 1.0), (0.5-lat/PI) );\
\
}\
\
void main()\
{\
mediump vec2 scaledCoords;\
mediump vec2 texCoords;\
\
scaledCoords = TexCoordOut * vec2(scale * aspect, scale);\
texCoords = directionToTexturePos(scaledCoords);\
\
    gl_FragColor = texture2D(s_texture, tmp);\
}";

/*
 vec2 rads = vec2(PI * 2., PI );\
 highp float PI 3.141592653589793\
 highp float PI_2 1.570796326794897\
 \
 float x = (TexCoordOut.x - 0.5) * scale;\
 float y = (TexCoordOut.y - 0.5) * scale * aspect;\
 \
 vec3 sphere_pnt = vec3(\
 (2. * x) / (1. + x*x + y*y),\
 (2. * y) / (1. + x*x + y*y),\
 (x*x + y*y - 1.) / (1. + x*x + y*y)\
 );\
 \
 sphere_pnt *= transform;\
 \
 float r = length(sphere_pnt);\
 float lon = atan(sphere_pnt.y, sphere_pnt.x);\
 float lat = acos(sphere_pnt.z / r);\
 \
 vec2 tmp=vec2(lon, lat) / rads;\
 \
 tmp.x += 0.5;\
 \
 
 
 */

char *const rgbFragmentShaderNormal = "precision mediump float;\
\
varying highp vec2 TexCoordOut;\
uniform sampler2D s_texture;\
\
void main()\
{\
    gl_FragColor = texture2D(s_texture, TexCoordOut);\
}";



#endif /* shaders_h */
