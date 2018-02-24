//
//  SYMovieDecoder.h
//  AVFoundation-test
//
//  Created by sunny on 2017/7/10.
//  Copyright © 2017年 www.LH.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYSunnyMovieGLView.h"
//#import "KxAudioManager.h"
// video decode type 0：软解码 1：硬解码
#define DECODETYPE 0

typedef enum {
    
    KxMovieFrameTypeAudio,
    KxMovieFrameTypeVideo,
    KxMovieFrameTypeArtwork,
    KxMovieFrameTypeSubtitle,
    
} KxMovieFrameType;

typedef enum {
    
    KxVideoFrameFormatRGB,
    KxVideoFrameFormatYUV,
    
} KxVideoFrameFormat;

@interface KxMovieFrame : NSObject
@property (readonly, nonatomic) KxMovieFrameType type;
@property (readonly, nonatomic) CGFloat position;
@property (readonly, nonatomic) CGFloat duration;
@end

@interface KxVideoFrame : KxMovieFrame
@property (readonly, nonatomic) KxVideoFrameFormat format;
@property (readonly, nonatomic) NSUInteger width;
@property (readonly, nonatomic) NSUInteger height;
@property (readonly, nonatomic, strong) NSData *imageBuf;
@end

@interface KxAudioFrame : KxMovieFrame
@property (readonly, nonatomic, strong) NSData *samples;
@end


@protocol SYMediaDelegate <NSObject>

- (void)callbackgetH264;

@end

@interface SYMovieDecoder : NSObject

+ (instancetype) movieDecoderWithContentPath: (NSString *)media_path error: (NSError **) perror;

- (int) openVideoStream;
- (int) openAudioStream;

- (NSArray *) decodeFrames: (CGFloat) minDuration;


- (void)initFormatContext:(NSString *)media_path;
- (int)loadTSData:(NSData *)data;

@property (nonatomic, weak) SYSunnyMovieGLView *glView;

@end
