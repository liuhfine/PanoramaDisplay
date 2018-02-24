//
//  display.c
//  SunnyTelescope
//
//  Created by sunny on 15/6/13.
//  Copyright (c) 2015年 com.sunnyoptical. All rights reserved.
//

#import "display.h"
#import "SYSunnyMovieGLView.h"

static SYSunnyMovieGLView *yv12_view = NULL;

int display_init(SYSunnyMovieGLView *view)
{
    yv12_view = view;
    return 0;
}

int display_showframe(unsigned char* frame, int w, int h)
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [yv12_view displayData:frame width:w height:h];
    });
    return 0;
}

int display_transform(float scale, float X, float Y)
{
    [yv12_view displayReloadTransformInfo:scale X:X Y:Y];
    return 0;
}

int display_reviewMode(ReviewMode reviewMode)
{
    [yv12_view displayReloadReviewMode:reviewMode];
    return 0;

}

int display_uninit()
{
    return 0;
}





//char * displaey_uninit()
//{
//    return ShaderAsteroid;
//}
