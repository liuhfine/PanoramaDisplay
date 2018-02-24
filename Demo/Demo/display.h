//
//  display.h
//  SunnyTelescope
//
//  Created by sunny on 15/6/13.
//  Copyright (c) 2015年 com.sunnyoptical. All rights reserved.
//

#ifndef __SunnyTelescope__display__
#define __SunnyTelescope__display__

#include <stdio.h>
#include "SYSunnyMovieGLView.h"

int display_init(SYSunnyMovieGLView *view);


/**
 showFrame
 使用前需执行display_init
 @param frame buffer
 @param w video width
 @param h video height
 @return 0
 */
int display_showframe(unsigned char* frame, int w, int h);

/**
 transform 
 
 @param scale 缩放 正数放大，反之缩小
 @param x 经度 绕Z轴旋转
 @param y 纬度
 */
int display_transform(float scale, float X, float Y);

int display_reviewMode(ReviewMode reviewMode);

int display_uninit();

//char * displaey_uninit();


#endif /* defined(__SunnyTelescope__display__) */
