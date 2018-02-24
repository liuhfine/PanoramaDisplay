//
//  OpenGLView.m
//  MyTest
//
//  Created by smy on 12/20/11.
//  Copyright (c) 2011 ZY.SYM. All rights reserved.
//

#import "SYSunnyMovieGLView.h"
#import <CoreMotion/CoreMotion.h>
//#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
//#import <OpenGLES/EAGL.h>
//#include <sys/time.h>
#import <GLKit/GLKit.h>
#import "shaders.h"
#import "facegen.h"

/**************************** renderers *******************************/
#pragma mark - frame renderers
 @protocol SYMovieGLRenderer
 - (BOOL)isValid;
 - (NSString *)vertexShader:(ReviewMode)reviewMode;
 - (NSString *)fragmentShader:(ReviewMode)reviewMode;
 - (void)resolveUniforms:(GLuint)program;
 - (void)setFrame:(void *)frame width:(float)width height:(float)height;
 - (BOOL)prepareRender;
 @end
     
 @interface SYMovieGLRenderer_RGB : NSObject<SYMovieGLRenderer> {
     
     GLint _uniformSampler;
     GLuint _texture;
 }
 @end
 
 @implementation SYMovieGLRenderer_RGB
 
 - (BOOL)isValid
 {
     return (_texture != 0);
 }

- (NSString *)vertexShader:(ReviewMode)reviewMode
{
    NSString *vertexShaderString;
    
    if(reviewMode == ReviewModeAsteroid)
    {
        vertexShaderString = [NSString stringWithFormat:@"%s",vertexShaderAsteroid];
        
        return vertexShaderString;
    }
    else{
        vertexShaderString = [NSString stringWithFormat:@"%s",vertexShaderNormal];
        
        return vertexShaderString;
    }
}

- (NSString *)fragmentShader:(ReviewMode)reviewMode;
 {
     NSString *fragmentShaderString;
     
     if(reviewMode == ReviewModeAsteroid)
     {
         fragmentShaderString = [NSString stringWithFormat:@"%s",rgbFragmentShaderAsteroid];
         
         return fragmentShaderString;
     }
     else
     {
         fragmentShaderString = [NSString stringWithFormat:@"%s",rgbFragmentShaderNormal];
         
         return fragmentShaderString;
     }
 }
 
 - (void)resolveUniforms:(GLuint)program
 {
     _uniformSampler = glGetUniformLocation(program, "s_texture");
 }
 
 - (void)setFrame:(void *)frame width:(float)width height:(float)height
 {

     glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
     
     if (0 == _texture)
         glGenTextures(1, &_texture);
     
     glBindTexture(GL_TEXTURE_2D, _texture);
     
     glTexImage2D(GL_TEXTURE_2D,
                  0,
                  GL_RGB,
                  width,
                  height,
                  0,
                  GL_RGB,
                  GL_UNSIGNED_BYTE,
                  (unsigned char *)frame);
     
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
 }
 
 - (BOOL) prepareRender
 {
     if (_texture == 0)
         return NO;
     
     glActiveTexture(GL_TEXTURE0);
     glBindTexture(GL_TEXTURE_2D, _texture);
     glUniform1i(_uniformSampler, 0);
     
     return YES;
 }
 
 - (void) dealloc
 {
     if (_texture) {
         glDeleteTextures(1, &_texture);
         _texture = 0;
     }
 }
 
 @end
     
 @interface SYMovieGLRenderer_YUV : NSObject<SYMovieGLRenderer> {
     
     GLint _uniformSamplers[3];
     GLuint _textures[3];
 }
 @end
 
 @implementation SYMovieGLRenderer_YUV
 
 - (BOOL)isValid
 {
     return (_textures[0] != 0);
 }

- (NSString *)vertexShader:(ReviewMode)reviewMode
{
    NSString *vertexShaderString;
    
    if(reviewMode == ReviewModeAsteroid)
    {
        vertexShaderString = [NSString stringWithFormat:@"%s",vertexShaderAsteroid];
        
        return vertexShaderString;
    }
    else{
        vertexShaderString = [NSString stringWithFormat:@"%s",vertexShaderNormal];
        
        return vertexShaderString;
    }
}

 - (NSString *)fragmentShader:(ReviewMode)reviewMode;
 {
     NSString *fragmentShaderString;
     
     if(reviewMode == ReviewModeAsteroid)
     {
         fragmentShaderString = [NSString stringWithFormat:@"%s",yuvFragmentShaderAsteroid];
         
         return fragmentShaderString;
     }
     else
     {
         fragmentShaderString = [NSString stringWithFormat:@"%s",yuvFragmentShaderNormal];
         
         return fragmentShaderString;
     }
 }

 - (void)resolveUniforms:(GLuint)program
 {
     _uniformSamplers[0] = glGetUniformLocation(program, "SamplerY");
     _uniformSamplers[1] = glGetUniformLocation(program, "SamplerU");
     _uniformSamplers[2] = glGetUniformLocation(program, "SamplerV");
 }
 
 - (void)setFrame:(void *)frame width:(float)width height:(float)height
 {

     const GLuint frameWidth = (GLuint)width;
     const GLuint frameHeight = (GLuint)height;
     
     glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
     
     if (0 == _textures[0])
         glGenTextures(3, _textures);
     
     const UInt8 *pixels[3] = { (unsigned char*)frame, (unsigned char*)frame + frameWidth * frameHeight, (unsigned char*)frame + frameWidth * frameHeight * 5 / 4 };
     const GLuint widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
     const GLuint heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
     
     for (int i = 0; i < 3; ++i) {
         
         glBindTexture(GL_TEXTURE_2D, _textures[i]);
         
         glTexImage2D(GL_TEXTURE_2D,
                      0,
                      GL_LUMINANCE,
                      widths[i],
                      heights[i],
                      0,
                      GL_LUMINANCE,
                      GL_UNSIGNED_BYTE,
                      pixels[i]);
         
         glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
         glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
         glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
         glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
     }
 }
 
 - (BOOL) prepareRender
 {
     if (_textures[0] == 0)
         return NO;
     
     for (int i = 0; i < 3; ++i) {
         glActiveTexture(GL_TEXTURE0 + i);
         glBindTexture(GL_TEXTURE_2D, _textures[i]);
         glUniform1i(_uniformSamplers[i], i);
     }
     
     return YES;
 }
 
 - (void) dealloc
 {
     if (_textures[0])
         glDeleteTextures(3, _textures);
 }
 
 @end

/**************************** model *******************************/
#pragma mark - model
#define ES_PI  (3.14159265f)

static const GLfloat squareVertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

static const GLfloat coordVertices[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f,  0.0f,
    1.0f,  0.0f,
};

int esGenSphere(int numSlices, float radius, float **vertices,
                float **texCoords, uint16_t **indices, int *numVertices_out) {
    
    int numParallels = numSlices / 2;
    int numVertices = (numParallels + 1) * (numSlices + 1);
    int numIndices = numParallels * numSlices * 6;
    float angleStep = (2.0f * ES_PI) / ((float) numSlices);
    
    if (vertices != NULL) {
        *vertices = malloc(sizeof(float) * 3 * numVertices);
    }
    
    if (texCoords != NULL) {
        *texCoords = malloc(sizeof(float) * 2 * numVertices);
    }
    
    if (indices != NULL) {
        *indices = malloc(sizeof(uint16_t) * numIndices);
    }
    
    for (int i = 0; i < numParallels + 1; i++) {
        for (int j = 0; j < numSlices + 1; j++) {
            int vertex = (i * (numSlices + 1) + j) * 3;
            
            if (vertices) {
                (*vertices)[vertex + 0] = radius * sinf(angleStep * (float)i) * sinf(angleStep * (float)j);
                (*vertices)[vertex + 1] = radius * cosf(angleStep * (float)i);
                (*vertices)[vertex + 2] = radius * sinf(angleStep * (float)i) * cosf(angleStep * (float)j);
            }
            
            if (texCoords) {
                int texIndex = (i * (numSlices + 1) + j) * 2;
                (*texCoords)[texIndex + 0] = (float)j / (float)numSlices;
                (*texCoords)[texIndex + 1] = 1.0f - ((float)i / (float)numParallels);
            }
        }
    }
    
    // Generate the indices
    if (indices != NULL) {
        uint16_t *indexBuf = (*indices);
        for (int i = 0; i < numParallels; i++) {
            for (int j = 0; j < numSlices; j++) {
                *indexBuf++ = i * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
                
                *indexBuf++ = i * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
                *indexBuf++ = i * (numSlices + 1) + (j + 1);
            }
        }
    }
    
    if (numVertices_out) {
        *numVertices_out = numVertices;
    }
    
    return numIndices;
}

/**************************** glView *******************************/
     
#pragma mark - glView
enum AttribEnum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXTURE,
    ATTRIB_COLOR,
};

enum TextureType
{
    TEXY = 0,
    TEXU,
    TEXV,
    TEXUV,
    TEXC
};

enum {
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    UNIFORM_Y,
    UNIFORM_UV,
    SCALE,
    ASPECT,
    RAMDA,
    FETA,
    isYUVOrRGB,
    NUM_UNIFORMS,
};
GLint uniforms[NUM_UNIFORMS];


#define DEFAULT_OVERTURE 85.0
#define SphereSliceNum 200
#define SphereRadius 1.0
#define SphereScale 300
#define ROLL_CORRECTION ES_PI/3.0

@interface SYSunnyMovieGLView()
{
    /**
     OpenGL绘图上下文
     */
    EAGLContext             *_glContext;
    
    /**
     帧缓冲区
     */
    GLuint                  _framebuffer;
    
    /**
     渲染缓冲区
     */
    GLuint                  _renderBuffer;
    
    /**
     着色器句柄
     */
    GLuint                  _program;
    
    /**
     YUV纹理数组
     */
    GLuint                  _textureYUV[3];
    
    /**
     RGB纹理数组
     */
    GLuint                  _textureRGB;
    /**
     视频宽度
     */
    GLuint                  _videoW;
    
    /**
     视频高度
     */
    GLuint                  _videoH;
    
    GLint                   _uniformMatrix;
    
    GLsizei                 _viewScale;
	   
    //void                    *_pYuvData;
    id<SYMovieGLRenderer> _renderer;

#ifdef DEBUG
    struct timeval      _time;
    NSInteger           _frameRate;
#endif
}

@property (assign, nonatomic) CGFloat overture;
@property (assign, nonatomic) CGFloat fingerRotationX;
@property (assign, nonatomic) CGFloat fingerRotationY;

@property (assign, nonatomic) int numIndices;
@property (assign, nonatomic) GLuint vertexIndicesBufferID;
@property (assign, nonatomic) GLuint vertexBufferID;
@property (assign, nonatomic) GLuint vertexTexCoordID;
@property (assign, nonatomic) GLuint vertexTexCoordAttributeIndex;

@property (assign, nonatomic) GLKMatrix4 modelViewProjectionMatrix;
@property (assign, nonatomic) BOOL isUsingMotion;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CMAttitude *referenceAttitude;
@property (assign, nonatomic) CGFloat savedGyroRotationX;
@property (assign, nonatomic) CGFloat savedGyroRotationY;

@property (assign, nonatomic) CVOpenGLESTextureRef lumaTexture;
@property (assign, nonatomic) CVOpenGLESTextureRef chromaTexture;
@property (assign, nonatomic) CVOpenGLESTextureCacheRef videoTextureCache;

/** 
 初始化YUV纹理
 */
- (void)setupYUVTexture;

/** 
 创建缓冲区
 @return 成功返回TRUE 失败返回FALSE
 */
- (BOOL)createFrameAndRenderBuffer;

/** 
 销毁缓冲区
 */
- (void)destoryFrameAndRenderBuffer;

//加载着色器
/** 
 初始化YUV纹理
 */
- (void)loadShader;

/** 
 编译着色代码
 @param shader        代码
 @param shaderType    类型
 @return 成功返回着色器 失败返回－1
 */
- (GLuint)compileShader:(NSString*)shaderCode withType:(GLenum)shaderType;

/** 
 渲染
 */
- (void)render;
@end

@implementation SYSunnyMovieGLView

- (void)dealloc
 {
     _renderer = nil;
     
     if (_framebuffer) {
         glDeleteFramebuffers(1, &_framebuffer);
         _framebuffer = 0;
     }
     
     if (_renderBuffer) {
         glDeleteRenderbuffers(1, &_renderBuffer);
         _renderBuffer = 0;
     }
     
     if (_program) {
         glDeleteProgram(_program);
         _program = 0;
     }
     
     if ([EAGLContext currentContext] == _glContext) {
         [EAGLContext setCurrentContext:nil];
     }
     
     _glContext = nil;
 }

- (void)setupGL {

    [EAGLContext setCurrentContext:_glContext];
    
    if (self.reviewMode == ReviewModeAsteroid)
    {
        glGenBuffers(1, &_vertexBufferID);
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferID);
        glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertices), &squareVertices, GL_STATIC_DRAW);
        
        int pos_location = glGetAttribLocation(_program, "position");
        glEnableVertexAttribArray(pos_location);// 开启顶点数据
        glVertexAttribPointer(pos_location,
                              2,
                              GL_FLOAT,
                              GL_FALSE,
                              8,
                              NULL);
        
        // Update attribute values
//        glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
//        glEnableVertexAttribArray(ATTRIB_VERTEX);
//        
//        glVertexAttribPointer(ATTRIB_TEXTURE, 2, GL_FLOAT, 0, 0, coordVertices);
//        glEnableVertexAttribArray(ATTRIB_TEXTURE);

        uniforms[RAMDA] = glGetUniformLocation(_program, "ramda");
        uniforms[FETA] = glGetUniformLocation(_program, "feta");
        uniforms[SCALE] = glGetUniformLocation(_program, "scale");
        uniforms[ASPECT] = glGetUniformLocation(_program, "aspect");
    }
    else
    {
        [self setupBuffers];
        
        uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program,"modelViewProjectionMatrix");
    }
    
    if (self.dataSourceType == DataSourceTypeYUV420) {
        GLuint textureUniformY = glGetUniformLocation(_program, "SamplerY");
        GLuint textureUniformU = glGetUniformLocation(_program, "SamplerU");
        GLuint textureUniformV = glGetUniformLocation(_program, "SamplerV");
        glUniform1i(textureUniformY, 0);
        glUniform1i(textureUniformU, 1);
        glUniform1i(textureUniformV, 2);
    }
    else
    {
        GLuint textureUniformRGB = glGetUniformLocation(_program, "s_texture");
        glUniform1i(textureUniformRGB, 0);
    }

}

- (void)setupBuffers {
    
    GLfloat *vVertices = NULL;
    GLfloat *vTextCoord = NULL;
    GLushort *indices = NULL;
    
//    int numVertices = 0;
//    self.numIndices = esGenSphere(SphereSliceNum, SphereRadius, &vVertices, &vTextCoord, &indices, &numVertices);
    
    //Indices 加载顶点索引数据
    glGenBuffers(1, &_vertexIndicesBufferID);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.vertexIndicesBufferID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, facegenNumVerts*sizeof(GLushort), facegenNormals, GL_STATIC_DRAW);
    
    // Vertex 加载顶点坐标
    glGenBuffers(1, &_vertexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBufferID);
    glBufferData(GL_ARRAY_BUFFER, facegenNumVerts*3*sizeof(GLfloat), facegenVerts, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, NULL);
    
    // Texture Coordinates 加载纹理坐标
    glGenBuffers(1, &_vertexTexCoordID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexTexCoordID);
    glBufferData(GL_ARRAY_BUFFER, facegenNumVerts*2*sizeof(GLfloat), facegenTexCoords, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_TEXTURE);
    glVertexAttribPointer(ATTRIB_TEXTURE, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
    
    // 释放内存
    free(vVertices);
    free(vTextCoord);
    free(indices);
}


- (BOOL)doInit
{
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                    nil];
    
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    _viewScale = [UIScreen mainScreen].scale;
    
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if(!_glContext || ![EAGLContext setCurrentContext:_glContext])
    {
        return NO;
    }
	
    [self setupYUVTexture]; // 加载纹理
    
    [self loadShader];    // 加载shader
    
    glUseProgram(_program);  // useProgram
    
    [self setupGL];  //

    [self setupVideoCache];
    
    return YES;
}

- (id)initWithFrame:(CGRect)frame
             dataSourceType:(DataSourceType)dataSourceType
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.dataSourceType = dataSourceType;
        
        if (self.dataSourceType == DataSourceTypeYUV420)
            _renderer = [[SYMovieGLRenderer_YUV alloc] init];
        else
            _renderer = [[SYMovieGLRenderer_RGB alloc] init];
        
        self.reviewMode = ReviewModeNormal;
        
        if (![self doInit])
        {
            self = nil;
        }
        self.overture = DEFAULT_OVERTURE;
    }
    return self;
    
    
}

- (void)layoutSubviews
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized(self)
        {
            [EAGLContext setCurrentContext:_glContext];
            [self destoryFrameAndRenderBuffer];
            [self createFrameAndRenderBuffer];
        }
        
//        glViewport(1, 1, self.bounds.size.width*_viewScale - 2, self.bounds.size.height*_viewScale - 2);
        glViewport(0, 0, self.bounds.size.width*2, self.bounds.size.height*2);
    });
}

- (void)setupYUVTexture
{
    
    if (self.dataSourceType == DataSourceTypeYUV420)
    {
        if (_textureYUV[TEXY])
        {
            glDeleteTextures(3, _textureYUV);
        }
        glGenTextures(3, _textureYUV);
        
        if (!_textureYUV[TEXY] || !_textureYUV[TEXU] || !_textureYUV[TEXV])
        {
            NSLog(@"<<<<<<<<<<<<纹理创建失败!>>>>>>>>>>>>");
            return;
        }
    }
    else
    {
        if (_textureRGB)
        {
            glDeleteTextures(1, &(_textureRGB));
        }
        glGenTextures(1, &(_textureRGB));
        
        if (!_textureRGB)
        {
            NSLog(@"<<<<<<<<<<<<纹理创建失败!>>>>>>>>>>>>");
            return;
        }
    }
    
    if (self.dataSourceType == DataSourceTypeYUV420) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    else
    {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _textureRGB);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}

- (void)render
{
    [EAGLContext setCurrentContext:_glContext];
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.bounds.size.width*2, self.bounds.size.height*2);
    
    [self updateInfo]; // 视口变换
    
    // Draw
    if (self.reviewMode == ReviewModeAsteroid)
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    else
        glDrawArrays(GL_TRIANGLE_STRIP, 0, facegenNumVerts);
//        glDrawElements(GL_TRIANGLES, facegenNumVerts, GL_UNSIGNED_SHORT, 0);

    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)updateInfo
{
    
    if (self.reviewMode == ReviewModeAsteroid)
    {
        glUniform1f(uniforms[RAMDA], self.fingerRotationX);
        glUniform1f(uniforms[FETA], self.fingerRotationY);
        //scale控制视野范围的缩放。scale约大，视野范围越大，物体缩得越小
        glUniform1f(uniforms[SCALE], self.overture/50.0);
        //屏幕宽高比，用于校正纵横比例
        glUniform1f(uniforms[ASPECT], self.bounds.size.width * 1.0 / self.bounds.size.height);
    }
    else
    {
        float aspect = fabs(self.bounds.size.width / self.bounds.size.height);
    
        // 创建模型矩阵
        GLKMatrix4 modelViewMatrix;
        if (self.reviewMode == ReviewModeNormal) {
            
            modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);
            float scale = 5.0;
            modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, scale, scale, scale); //缩放
            
            float aspect = fabs(self.bounds.size.width / self.bounds.size.height);
            GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.overture), aspect, 0.1f, 100.0f);
            
            modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.fingerRotationX);
            modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.fingerRotationY);
//            modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, self.fingerRotationY);
            
            self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
            glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, GL_FALSE, self.modelViewProjectionMatrix.m);
            
            return;
        }
        else
        {
            modelViewMatrix = GLKMatrix4Identity;
            float scale = SphereScale;
            modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, scale, scale, scale); //缩放
        
            GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.overture), aspect, 0.1f, 400.0f); // 透视投影变换
            projectionMatrix = GLKMatrix4Rotate(projectionMatrix, ES_PI, 1.0f, 0.0f, 0.0f); // 绕轴旋转
            
            if(self.isUsingMotion) {
                CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
                if (deviceMotion != nil) {
                    CMAttitude *attitude = deviceMotion.attitude;
                    
                    if (self.referenceAttitude != nil) {
                        [attitude multiplyByInverseOfAttitude:self.referenceAttitude];
                    } else {
                        self.referenceAttitude = deviceMotion.attitude;
                    }
                    
                    float cRoll = -fabs(attitude.roll);//fabs(attitude.roll); // Up/Down landscape 景象
                    float cYaw = attitude.yaw;  // Left/ Right landscape
                    float cPitch = attitude.pitch; // Depth landscape
                    
                    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
                    if (orientation == UIDeviceOrientationLandscapeRight ){
                        cPitch = cPitch*-1; // correct depth when in landscape right
                    }
                    
                    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, cRoll); // Up/Down axis
                    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, cPitch);
                    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, cYaw);
                    
                    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, ROLL_CORRECTION);
                    
                    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.fingerRotationX);
                    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.fingerRotationY);
                    
                    self.savedGyroRotationX = cRoll + ROLL_CORRECTION + self.fingerRotationX;
                    self.savedGyroRotationY = cPitch + self.fingerRotationY;
                }
            } else
            {
                modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.fingerRotationX);
                modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.fingerRotationY);
            }

            // 最终传入到GLSL中去的矩阵
            self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
            
            // 将最终变换矩阵传入shader程序
            glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, GL_FALSE, self.modelViewProjectionMatrix.m);

        }
    }
}

#pragma mark - 设置openGL
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (BOOL)createFrameAndRenderBuffer
{
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    if (![_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer])
    {
        NSLog(@"attach渲染缓冲区失败");
    }
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"创建缓冲区错误 0x%x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    return YES;
}

- (void)destoryFrameAndRenderBuffer
{
    if (_framebuffer)
    {
        glDeleteFramebuffers(1, &_framebuffer);
    }
    
    if (_renderBuffer)
    {
        glDeleteRenderbuffers(1, &_renderBuffer);
    }
    
    _framebuffer = 0;
    _renderBuffer = 0;
}

/** 
 加载着色器
 */
- (void)loadShader
{
	/**
	 1
	 */
    GLuint vertexShader = 0;
    GLuint fragmentShader = 0;

    vertexShader = [self compileShader:[_renderer vertexShader:self.reviewMode] withType:GL_VERTEX_SHADER];
    
    fragmentShader = [self compileShader:[_renderer fragmentShader:self.reviewMode] withType:GL_FRAGMENT_SHADER];
    
	/** 
	 2
	 */
    _program = glCreateProgram();
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    
	/** 
	 绑定需要在link之前
	 */
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXTURE, "TexCoordIn");
    
    glLinkProgram(_program);
    

	/** 
	 3
	 */
    GLint linkSuccess;
    glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"<<<<着色器连接失败 %@>>>", messageString);
        //exit(1);
    }
    
    if (vertexShader)
		glDeleteShader(vertexShader);
    if (fragmentShader)
		glDeleteShader(fragmentShader);
}

- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType
{
    
   	/** 
	 1
	 */
    if (!shaderString) {
        NSLog(@"Error loading shader");
        exit(1);
    }
    else
    {
        //NSLog(@"shader code-->%@", shaderString);
    }
    
	/** 
	 2
	 */
    GLuint shaderHandle = glCreateShader(shaderType);    
    if (shaderHandle == 0 || shaderHandle == GL_INVALID_ENUM) {
        NSLog(@"Failed to create shader %d", shaderType);
        return 0;
    }
    
	/** 
	 3
	 */
    const GLchar *sources = (GLchar *)shaderString.UTF8String;
    glShaderSource(shaderHandle, 1, &sources, NULL);
    
	/** 
	 4
	 */
    glCompileShader(shaderHandle);
    
	/** 
	 5
	 */
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@">>>>>%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}

- (void)setupVideoCache {
    if (!self.videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _glContext, NULL, &_videoTextureCache);
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
    }
}

- (void)cleanUpTextures {
    if (self.lumaTexture) {
        CFRelease(_lumaTexture);
        self.lumaTexture = NULL;
    }
    
    if (self.chromaTexture) {
        CFRelease(_chromaTexture);
        self.chromaTexture = NULL;
    }
    
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

#pragma mark - public API
- (void)refreshTexture:(CVPixelBufferRef)pixelBuffer
{
    if (pixelBuffer != nil) {
        
        GLsizei textureWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
        GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
        
        if (!self.videoTextureCache) {
            NSLog(@"No video texture cache");
            return;
        }
        
        CVReturn err;
        [self cleanUpTextures];
        
        // Y-plane
        glActiveTexture(GL_TEXTURE0);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           self.videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RED_EXT,
                                                           textureWidth,
                                                           textureHeight,
                                                           GL_RED_EXT,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &_lumaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        //         UV-plane.
        glActiveTexture(GL_TEXTURE1);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           self.videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RG_EXT,
                                                           textureWidth/2,
                                                           textureHeight/2,
                                                           GL_RG_EXT,
                                                           GL_UNSIGNED_BYTE,
                                                           1,
                                                           &_chromaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        [self render];
    }
}

- (void)displayData:(void *)data width:(NSInteger)w height:(NSInteger)h
{
    if (!self.window)
    {
        return;
    }
    @synchronized(self)
    {
        
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        
        [EAGLContext setCurrentContext:_glContext];
        
        if (self.dataSourceType == DataSourceTypeRGB42) {
            glBindTexture(GL_TEXTURE_2D, _textureRGB);
            
            if (w != _videoW || h != _videoH)
            {
                _videoW = (GLuint)w;
                _videoH = (GLuint)h;
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _videoW, _videoH, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
                
            }
            else
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _videoW, _videoH, GL_RGB, GL_UNSIGNED_BYTE, data);
        }
        else
        {
//            if (w != _videoW || h != _videoH)
//            {
//                _videoW = (GLuint)w;
//                _videoH = (GLuint)h;
//
//                [self setVideoSize:_videoW height:_videoH];
//            }
//            [EAGLContext setCurrentContext:_glContext];
//
//            glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
//            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _videoW, _videoH, GL_RED_EXT, GL_UNSIGNED_BYTE, data);
//
//            //[self debugGlError];
//
//            glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
//            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _videoW/2, _videoH/2, GL_RED_EXT, GL_UNSIGNED_BYTE, (unsigned char*)data + w * h);
//
//            // [self debugGlError];
//
//            glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
//            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _videoW/2, _videoH/2, GL_RED_EXT, GL_UNSIGNED_BYTE, (unsigned char*)data + w * h * 5 / 4);
            
        }
        [self render];
    }
    
#ifdef DEBU
    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
    {
        printf("GL_ERROR=======>%d\n", err);
    }
    struct timeval nowtime;
    gettimeofday(&nowtime, NULL);
    if (nowtime.tv_sec != _time.tv_sec)
    {
        printf("视频 %ld 帧率:   %ld\n", (long)self.tag, (long)_frameRate);
        memcpy(&_time, &nowtime, sizeof(struct timeval));
        _frameRate = 1;
    }
    else
    {
        _frameRate++;
    }
#endif

}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:_glContext];
    
    glDeleteBuffers(1, &_vertexIndicesBufferID); // 删除 顶点缓存对象(VBO)
    glDeleteBuffers(1, &_vertexBufferID);
    glDeleteBuffers(1, &_vertexTexCoordID);

}

- (void)displayReloadReviewMode:(ReviewMode)reviewMode;
{
    [self tearDownGL];
    
    self.reviewMode = reviewMode;
    if (_program)
    {
        glDeleteShader(_program);
    }
    
    [self loadShader];    // 加载shader
    
    glUseProgram(_program);  // useProgram
    
    [self setupGL];  //
    
}

- (void)displayReloadTransformInfo:(float)scale X:(float)x Y:(float)y
{
    if (self.isUsingMotion) return;
    
    self.fingerRotationX = x;
    self.fingerRotationY = y;
    
    self.overture = scale;
    
    NSLog(@"\n>>>>>>X--------:%.2f\nY<<<<<<<<------:%.2f\nscale<<<<<<<<%f",self.fingerRotationX,self.fingerRotationY,self.overture);
    
}

- (void)setVideoSize:(GLuint)width height:(GLuint)height
{
    unsigned char *blackData = (unsigned char*)malloc(width * height * 3 / 2);
	if(blackData)
        memset(blackData, 0x0, width * height * 3 / 2);
    
    [EAGLContext setCurrentContext:_glContext];
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width, height, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData + width * height);
    
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData + width * height * 5 / 4);
    free(blackData);
}

- (void)isMotionWithUsing:(BOOL)Using;
{
    if (Using)
        [self startDeviceMotion];
    else
        [self stopDeviceMotion];
}

- (void)clearFrame
{
    if ([self window])
    {
        [EAGLContext setCurrentContext:_glContext];
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
        [_glContext presentRenderbuffer:GL_RENDERBUFFER];
    }
    
}

#pragma mark - Device Motion

- (void)startDeviceMotion {
    self.isUsingMotion = NO;
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.referenceAttitude = nil;
    self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
    self.motionManager.gyroUpdateInterval = 1.0f / 60;
    self.motionManager.showsDeviceMovementDisplay = YES;
    
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
    
    self.referenceAttitude = self.motionManager.deviceMotion.attitude; // Maybe nil actually. reset it later when we have data
    
    self.savedGyroRotationX = 0;
    self.savedGyroRotationY = 0;
    
    self.isUsingMotion = YES;
}

- (void)stopDeviceMotion {
    self.fingerRotationX = self.savedGyroRotationX-self.referenceAttitude.roll- ROLL_CORRECTION;
    self.fingerRotationY = self.savedGyroRotationY;
    
    self.isUsingMotion = NO;
    [self.motionManager stopDeviceMotionUpdates];
    self.motionManager = nil;
}

@end

/*
 
 //初始化
 OpenGLView20 *glView = [[OpenGLView20 alloc] initWithFrame:frame];
 //设置视频原始尺寸
 [glView setVideoSize:352 height:288];
 //渲染yuv
 [glView displayYUV420pData:yuvBuffer width:352height:288;
 //将352,288换成你自己的
 */
