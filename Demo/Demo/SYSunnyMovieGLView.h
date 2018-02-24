//
//  OpenGLView20.h
//  MyTest
//
//  Created by smy  on 12/20/11.
//  Copyright (c) 2011 ZY.SYM. All rights reserved.
//
#ifndef __OPENGL_VIEW_H__
#define __OPENGL_VIEW_H__

#import <UIKit/UIKit.h>

@interface SYSunnyMovieGLView : UIView

typedef NS_ENUM(NSUInteger, ReviewMode) {
    ReviewModePanorama = 10,
    ReviewModeNormal,
    ReviewModeAsteroid
};

typedef NS_ENUM(NSUInteger, DataSourceType) {
    DataSourceTypeYUV420 = 100,
    DataSourceTypeRGB42
};

@property (nonatomic,assign) ReviewMode reviewMode;
@property (nonatomic,assign) DataSourceType dataSourceType;

#pragma mark - 接口
- (id)initWithFrame:(CGRect)frame dataSourceType:(DataSourceType)dataSourceType;

- (void)refreshTexture:(CVPixelBufferRef)videoFrame;

/**
 h264 数据
 */
- (void)displayData:(void *)data width:(NSInteger)w height:(NSInteger)h;

- (void)displayReloadTransformInfo:(float)scale X:(float)x Y:(float)y;

/**
 ReviewMode

 @param reviewMode
 */
- (void)displayReloadReviewMode:(ReviewMode)reviewMode;

- (void)setVideoSize:(GLuint)width height:(GLuint)height;


/**
 使用陀螺仪和加速器
 */
- (void)isMotionWithUsing:(BOOL)Using;

/** 
 清除画面
 */
- (void)clearFrame;

@end

#endif
