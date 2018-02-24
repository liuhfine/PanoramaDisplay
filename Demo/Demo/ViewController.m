//
//  ViewController.m
//  Demo
//
//  Created by sunny on 2017/4/17.
//  Copyright © 2017年 HL. All rights reserved.
//

#import "ViewController.h"
#import "display.h"
#import "SYSunnyMovieGLView.h"
#import "SYMovieDecoder.h"

#define MAX_OVERTURE 95.0
#define MIN_OVERTURE 15.0
#define DEFAULT_OVERTURE 65.0

@interface ViewController ()
{
    SYSunnyMovieGLView *glView;
    int timer_tick;
    int cap_timer;
    NSTimer *timer;
}
@property (strong, nonatomic) NSMutableArray *currentTouches;
@property (assign, nonatomic) CGFloat overture;
@property (assign, nonatomic) CGFloat fingerRotationX;
@property (assign, nonatomic) CGFloat fingerRotationY;
@property (strong, nonatomic) UILabel *scale;
@end

unsigned char* yuv_buffer = NULL;

@implementation ViewController
-(void) timerFunction:(void*)userInfo
{
//    display_showframe(yuv_buffer, 1920, 960);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [glView displayData:nil width:1080 height:720];
    });
    
}

- (void)dealloc
{
    free(yuv_buffer);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    glView = [[SYSunnyMovieGLView alloc] initWithFrame:frame dataSourceType:DataSourceTypeYUV420];
//    [glView displayReloadReviewMode:ReviewModeAsteroid];
    glView.center = self.view.center;
    [self.view addSubview:glView];
    [glView isMotionWithUsing:NO];
    
//    NSString *ff = [[NSBundle mainBundle] pathForResource:@"testqqq" ofType:@"ts"];
////    NSString *path = @"http://www.qeebu.com/newe/Public/Attachment/99/52958fdb45565.mp4";
//    SYMovieDecoder *mp = [SYMovieDecoder movieDecoderWithContentPath:ff error:nil];
//    mp.glView = glView;
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
//        BOOL good = YES;
//        while (good) {
//            [mp decodeFrames:0];
//            sleep(0.5);
//        }
//    });
    
    
//    display_init(glView);
    
    self.overture = DEFAULT_OVERTURE;
    [self addGesture];
    [self createUI];
    
//    [glView displayReloadTransformInfo:0.2 X:1.0 Y:1.0];
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//        [glView displayData:nil width:1080 height:720];
//    });
    
    
//    cap_timer = -1;
//    timer_tick = 0;
    timer =  [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(timerFunction:) userInfo:nil repeats:YES];
//    NSLog(@"Stream_Start+++");
    
    /******** 读取YUV数据 dataSource **********/
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"1920x960" ofType:@"I420"];

    const char * path = [filePath UTF8String];

    yuv_buffer = malloc(1920*960*3/2);

    FILE *fp = fopen(path, "rb");
    if(fp)
    {
        fread(yuv_buffer, 1, 1920*960*3/2, fp);
        fclose(fp);
    }
    
    //    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"video-1920x960-poster" ofType:@"rgb24"];
    //
    //    const char * path = [filePath UTF8String];
    //
    //    yuv_buffer = malloc(1920*960*3);
    //
    //    FILE *fp = fopen(path, "rb");
    //    if(fp)
    //    {
    //        fread(yuv_buffer, 1, 1920*960*3, fp);
    //        fclose(fp);
    //    }

}

#pragma mark - createUI
static int num = 0;
- (void)createUI
{
    UILabel *scale = [[UILabel alloc] initWithFrame:CGRectMake(5, [UIScreen mainScreen].bounds.size.height/2.0 - 35/2.0, 60, 35)];
    scale.backgroundColor = [UIColor redColor];
    scale.textAlignment = NSTextAlignmentCenter;
    scale.textColor = [UIColor whiteColor];
    scale.font = [UIFont systemFontOfSize:18];
    self.scale = scale;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 65, [UIScreen mainScreen].bounds.size.height/2.0 - 35/2.0, 60, 35);
    [btn setBackgroundColor:[UIColor cyanColor]];
    [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:scale];
    [self.view addSubview:btn];
    
}

- (void)btnAction:(UIButton *)btn
{
    num += 1;
    if (num == 0)
    {
        display_reviewMode(ReviewModePanorama);
        [btn setTitle:@"全景" forState:UIControlStateNormal];
    }
    else if (num ==1)
    {
        display_reviewMode(ReviewModeAsteroid);
        [btn setTitle:@"小行星" forState:UIControlStateNormal];
    }
    else
    {
        display_reviewMode(ReviewModeNormal);
        num = -1;
        [btn setTitle:@"鱼眼" forState:UIControlStateNormal];
    }
    
    // GLView delegate
    
}

#pragma mark - Touch Event
- (void)addGesture
{
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    
    [self.view addGestureRecognizer:pinchRecognizer];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //    if(self.isUsingMotion) return;
    for (UITouch *touch in touches) {
        [_currentTouches addObject:touch];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    //    if(self.isUsingMotion) return;
    UITouch *touch = [touches anyObject];
    float distX = [touch locationInView:touch.view].x - [touch previousLocationInView:touch.view].x;
    float distY = [touch locationInView:touch.view].y - [touch previousLocationInView:touch.view].y;
    distX *= -0.005;
    distY *= -0.005;
    self.fingerRotationX += distY *  self.overture / 100;
    self.fingerRotationY -= distX *  self.overture / 100;
    
    self.fingerRotationX = self.fingerRotationX >= 2.55 ? 2.55 : self.fingerRotationX;
    self.fingerRotationX = self.fingerRotationX <= 0.55 ? 0.55 : self.fingerRotationX;
    
    [glView displayReloadTransformInfo:self.overture X:(float)self.fingerRotationX Y:(float)self.fingerRotationY];
//    display_transform(self.overture, (float)self.fingerRotationX, (float)self.fingerRotationY);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //    if (self.isUsingMotion) return;
    for (UITouch *touch in touches) {
        [self.currentTouches removeObject:touch];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        [self.currentTouches removeObject:touch];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    self.overture /= recognizer.scale;
    
    //    self.scale.text = ;
    
    NSLog(@"^^^^^^^^^^^^^^^:%@",[NSString stringWithFormat:@"%.1f",self.overture]);
    if (self.overture > MAX_OVERTURE) {
        self.overture = MAX_OVERTURE;
    }
    
    if (self.overture < MIN_OVERTURE) {
        self.overture = MIN_OVERTURE;
    }
    
    self.scale.text = [NSString stringWithFormat:@"%.2f",self.overture];
    
    recognizer.scale = 1;
    
    display_transform(self.overture, self.fingerRotationX, self.fingerRotationY);
    
}



@end
