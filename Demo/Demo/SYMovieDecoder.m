//
//  SYMovieDecoder.m
//  AVFoundation-test
//
//  Created by sunny on 2017/7/10.
//  Copyright © 2017年 www.LH.com. All rights reserved.
//

#import "SYMovieDecoder.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswresample/swresample.h"
#import <Accelerate/Accelerate.h>
#import <VideoToolbox/VideoToolbox.h>
#include <pthread.h>

//#import "SYCamPlaySound.h"
//#include "circlemem.h"
//#import "TestPcmPlay.h"
//#include "TPCircularBuffer.h"

@interface KxMovieFrame()
@property (readwrite, nonatomic) CGFloat position;
@property (readwrite, nonatomic) CGFloat duration;
@end

@implementation KxMovieFrame
@end


@interface KxVideoFrame ()
@property (readwrite, nonatomic) NSUInteger width;
@property (readwrite, nonatomic) NSUInteger height;
@property (readwrite, nonatomic, strong) NSData *imageBuf;
@end

@implementation KxVideoFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeVideo; }
@end

@interface KxAudioFrame()
@property (readwrite, nonatomic, strong) NSData *samples;
@end

@implementation KxAudioFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeAudio; }
@end


#define DUMMY_SINK_RECEIVE_BUFFER_SIZE 512000

@interface SYMovieDecoder ()
{
   
    NSThread *thread;
//    SYCamPlaySound *_soundPlay;
//    TestPcmPlay *_pcmPlay;
    void* fReceiveBuffer;
    
    uint8_t *_buf_out; // 原始接收的重组数据包
}
@end

@implementation SYMovieDecoder
{
    AVFormatContext *_formatCtx;
    AVCodecContext  *_videoCodCtx;
    AVCodecContext  *_audioCodCtx;
    AVCodec         *_videoCodec;
    AVCodec         *_audioCodec;
    AVFrame         *_videoFrame;
    AVFrame         *_audioFrame;
    
    int             _videoStream;
    int             _audioStream;
    
    SwrContext      *_swrContext;
    void            *_swrBuffer;
    NSUInteger       _swrBufferSize;
    CGFloat          _audioTimeBase;
    
    CGFloat          _position;
    
    int              _videoWidth;
    int              _videoheight;
}



static unsigned char* yv12_buffer = NULL;

#define BUF_SIZE 188*17
//HOCM  hocm = NULL;
int is_running = 0;
FILE *pIn_ts;
int fileToend = 0;

+ (instancetype) movieDecoderWithContentPath: (NSString *)media_path error: (NSError **) perror
{
    
    SYMovieDecoder *mp = [[SYMovieDecoder alloc] init];
    
    if (mp) {
        
        [mp initFormatContext:media_path];
    }
    
    return mp;
    
}

//- (BOOL)Stream_Start:(NSString *)media_path
//{
//    // 本地文件 or 网络流
////    _isNetwork = isNetworkPath(path);
//    
//    return NO;
//}

- (void) dealloc
{
    NSLog(@"%@ dealloc", self);
    [self closeFile];
}

- (void)closeFile
{
    
//    _videoStreams = nil;
//    _audioStreams = nil;
//    _subtitleStreams = nil;
    
    if (_formatCtx) {
        
        _formatCtx->interrupt_callback.opaque = NULL;
        _formatCtx->interrupt_callback.callback = NULL;
        
        avformat_close_input(&_formatCtx);
        _formatCtx = NULL;
    }

}


int read_data(void *opaque, uint8_t *buf, int buf_size) {
    int len = 0;
    while(is_running)
    {
//        len = ocmGet(hocm, buf, buf_size);
        if(len != 0)
        {
            break;
        }
        usleep(5000);
    }
    return len;
}

- (int)loadTSData:(NSData *)data
{
//    ocmPut( hocm, (__bridge void *)(data), (int)data.length);
    
    return 0;
}

- (void)initFormatContext:(NSString *)media_path
{
//    u_int8_t *ff[DUMMY_SINK_RECEIVE_BUFFER_SIZE];
//    fReceiveBuffer = (u_int8_t *)ff ;
//    hocm= ocmAlloc(2*1024*1024);

  
//    thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
//    thread.name = @"Thread333";
//    [thread start];

//    _soundPlay = [[SYCamPlaySound alloc] init];
//    _pcmPlay = [TestPcmPlay sharePalyer];
//    [_pcmPlay startPlayer];

    av_register_all(); // 注册所有解码器
    avformat_network_init();
    
/***************************** h264buf input *************************************/
#if 0
    uint8_t *buf = (uint8_t*)av_mallocz(sizeof(uint8_t)*BUF_SIZE);
   
    AVInputFormat *piFmt = NULL;
    AVFormatContext *pFmt = NULL;
    AVIOContext * pb = NULL;
    
    pb = avio_alloc_context(buf, BUF_SIZE, 0, NULL, read_data, NULL, NULL);
    if (!pb) {
        fprintf(stderr, "avio alloc failed!\n");
    }

    if (av_probe_input_buffer(pb, &piFmt, "", NULL, 0, 4096) < 0) {
        fprintf(stderr, "probe failed!\n");
    } else {
        fprintf(stdout, "probe success!\n");
        fprintf(stdout, "format: %s[%s]\n", piFmt->name, piFmt->long_name);
    }
    
    pFmt = avformat_alloc_context();
    pFmt->pb = pb;
    if (avformat_open_input(&pFmt, "", piFmt, NULL) < 0) {
        fprintf(stderr, "avformat open failed.\n");
        return ;
    } else {
        fprintf(stdout, "open stream success!\n");
    }
    
    if (avformat_find_stream_info(pFmt, NULL) < 0) {
        fprintf(stderr, "could not find stream.\n");
        return ;
    }

    av_dump_format(pFmt, 0, "", 0);
    
    _formatCtx = pFmt;
#endif
/***************************** h264buf input *************************************/
    
/***************************** filePath input *************************************/
    AVFormatContext *pFormatCtx = avformat_alloc_context();

    if (!pFormatCtx) {
        printf("is pFormatCtx NULL");
    }
    
    // 打开多媒体文件，并读取相关文件头信息。
    if (avformat_open_input(&pFormatCtx, [media_path UTF8String], NULL, NULL) < 0) {
        if (pFormatCtx)
            avformat_free_context(pFormatCtx);
        return ; // kxMovieErrorOpenFile
    }
    
    // 检索流信息
    if (avformat_find_stream_info(pFormatCtx, NULL) < 0) {
        
        avformat_close_input(&pFormatCtx);
        return ; // kxMovieErrorStreamInfoNotFound
    }
    
    av_dump_format(pFormatCtx, 0, [media_path UTF8String], false);
    
    _formatCtx = pFormatCtx;
/***************************** filePath input *************************************/
    
}

- (int) openVideoStream
{
#if 1
    if (_formatCtx == NULL) {
        return 1;
    }
    
    int videoindex = -1;
    for (int i = 0; i < _formatCtx->nb_streams; i++) {
        if ( (_formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) &&
            (videoindex < 0) ) {
            videoindex = i;
        }
    }

    if (videoindex < 0) {
        NSLog(@"Didn't find a video stream");
        return 1;
    }
    
    _videoStream = videoindex;
    
    // Get a pointer to the codec context for the video stream
    AVCodecContext *pVideoCodecCtx = _formatCtx->streams[videoindex]->codec;
    
    // Find the decoder for the video stream
    AVCodec *pVideoCodec = avcodec_find_decoder(pVideoCodecCtx->codec_id);
    
    if (pVideoCodec == NULL) {
        return 1;
    }
    
    // 获取视频宽度和高度
    int width = pVideoCodecCtx->width;
    int height = pVideoCodecCtx->height;
    
    _videoWidth = width;
    _videoheight = height;
    
    _videoCodCtx = pVideoCodecCtx;
    
    _videoCodec = pVideoCodec;
    
//    if(avcodec_open2(_videoCodCtx, _videoCodec,NULL)<0){
//        printf("Could not open codec.\n");
//        return 1;
//    }
#endif
    return 0;
}

- (int) openAudioStream
{
    if (_formatCtx == NULL) {
        return 1;
    }
    // handle stream info 找到第一个音频
    int audioindex = -1;
    for (int i = 0; i < _formatCtx->nb_streams; i++) {
        if ( (_formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) &&
            (audioindex < 0) ) {
            audioindex = i;
        }
    }
    
    if (audioindex < 0) {
        fprintf(stderr, "audioindex=%d\n", audioindex);
        //        return ;
    }
    
    _audioStream = audioindex;

   /******************************************************************************************/
    if (_audioStream == -1)
        return 1;
    
    // Get a pointer to the codec context for the audio stream
    AVCodecContext *pAudioCodecCtx = _formatCtx->streams[audioindex]->codec;
    
    // Find the decoder for the audio stream
    AVCodec *pAudioCodec = avcodec_find_decoder(pAudioCodecCtx->codec_id);
    
    if(!pAudioCodec)
        return 1;
    
    // Open codec
    if(avcodec_open2(pAudioCodecCtx, pAudioCodec,NULL) < 0)
        return 1;
    
    //Out Audio Param //音频输出参数
//    uint64_t out_channel_layout = AV_CH_LAYOUT_STEREO; //声道格式
//    int out_nb_samples = pAudioCodecCtx->frame_size; //nb_samples: AAC-1024 MP3-1152
//    //    AVSampleFormat out_sample_fmt = AV_SAMPLE_FMT_S16; //采样格式
//    int out_sample_rate = 44100;//采样率
//    int out_channels = av_get_channel_layout_nb_channels(out_channel_layout); //根据声道格式返回声道个数
//    //Out Buffer Size
//    int out_buffer_size = av_samples_get_buffer_size(NULL,out_channels ,out_nb_samples,AV_SAMPLE_FMT_S16, 1);
//    uint8_t *out_buffer = (uint8_t *)av_malloc(MAX_AUDIO_FRAME_SIZE);
//    int64_t in_channel_layout = av_get_default_channel_layout(pAudioCodecCtx->channels);
    
    //swr
    SwrContext *swrContext = NULL;
    
//    id<KxAudioManager> audioManager = [KxAudioManager audioManager];
//    swrContext = swr_alloc_set_opts(NULL,
//                                    av_get_default_channel_layout(audioManager.numOutputChannels),
//                                    AV_SAMPLE_FMT_S16,
//                                    audioManager.samplingRate,
//                                    av_get_default_channel_layout(pAudioCodecCtx->channels),
//                                    pAudioCodecCtx->sample_fmt,
//                                    pAudioCodecCtx->sample_rate,
//                                    0,
//                                    NULL);
    
    if (!swrContext ||
        swr_init(swrContext)) {
        
        if (swrContext)
            swr_free(&swrContext);
        avcodec_close(pAudioCodecCtx);
        
    }
    
    _audioFrame = av_frame_alloc();
    if (!_audioFrame) {
        if (swrContext)
            swr_free(&swrContext);
        avcodec_close(pAudioCodecCtx);
        return 1;
    }
    
    _audioCodCtx = pAudioCodecCtx;
    _swrContext = swrContext;
    
    return 0;
}

//- (int) openMediaStream
//{
//    // 1, handle stream info 找到第一个音频
//    int videoindex = -1;
//    int audioindex = -1;
//    for (int i = 0; i < _formatCtx->nb_streams; i++) {
//        if ( (_formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) &&
//            (videoindex < 0) ) {
//            videoindex = i;
//        }
//        if ( (_formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) &&
//            (audioindex < 0) ) {
//            audioindex = i;
//        }
//    }
//    
//    if (videoindex < 0 || audioindex < 0) {
//        fprintf(stderr, "videoindex=%d, audioindex=%d\n", videoindex, audioindex);
//        return 1;
//    }
//    
//    _audioStream = audioindex;
//    _videoStream = videoindex;
//    
//    
//    return 0;
//}

- (void)run {
    size_t out_size = 0;
    
    NSLog(@"ffdgfdgfd");
    while (![[NSThread currentThread] isCancelled]) {
        /*这里从网路端循环获取视频数据*/
//        if (api_video_get(_uid, _vdata, &out_size) == 0 && out_size > 0) {
//            if ([self decodeNalu:_vdata withSize:out_size]) {
//            }
//        }
        
        
        [NSThread sleepForTimeInterval:0.005];
    }
}


/**  // 功能模块封装，模块集成
 * 解封装，初始化解码器，注册AVFormatContext上下文，返回AVFormatContext 句柄
 * 派发解封装后的音，视频流 PES
 * 解码音，视频流 PES 得到ES流
 *
 @param minDuration 1
 */

#define MAX_AUDIO_FRAME_SIZE 192000 // 192000 176400// 1 second of 48khz 32bit audio
static int count_i = 0;
FILE *fp_vides = NULL;
- (NSArray *) decodeFrames: (CGFloat) minDuration
{
    if (fp_vides == NULL) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        NSString *documentsDirectory = [[paths objectAtIndex:0] stringByAppendingString:@"/"];
        NSString *video = [documentsDirectory stringByAppendingString:@"videoStream.h264"];
        NSString *audio = [documentsDirectory stringByAppendingString:@"audioStream.aac"];
        NSString *audio_pcm = [documentsDirectory stringByAppendingString:@"audio_pcm_Stream.pcm"];
        
        char file1[256];
        strcpy(file1, [video UTF8String]);
        
        char file2[256];
        strcpy(file2, [audio UTF8String]);
        
        char file3[256];
        strcpy(file3, [audio_pcm UTF8String]);
        
        
//        FILE *fp_vides = NULL, *fp_audes = NULL,*fp_audes_pcm = NULL;
        
        fp_vides = fopen(file1, "wb");
//        fp_audes = fopen(file2, "wb");
//        fp_audes_pcm = fopen(file3, "wb");
    }
    
    
    /******************************************************************************************/
    if (_videoStream == -1 && _audioStream == -1)
        return nil;
    
    NSMutableArray *result = [NSMutableArray array];
    
    CGFloat decodedDuration = 0;
    
    BOOL finished = NO;
    
    AVPacket pkt;
    
    AVBitStreamFilterContext* h264bsfc =  av_bitstream_filter_init("h264_mp4toannexb");
    
    while (!finished) {
        
        // 注册文件格式解析器，读取文件信息：
        if (av_read_frame(_formatCtx, &pkt) < 0) {
//            _isEOF = YES;
            break;
        }
        
        if (pkt.stream_index ==_videoStream)
        {
            //Write h264
//            fwrite(pkt.data, pkt.size, 1, fp_vides);
            
            CVImageBufferRef imageBuffer = H264decode_frame_viodeToolBox( pkt.data , pkt.size);
    
//            dispatch_sync(dispatch_get_main_queue(), ^{
                [_glView refreshTexture:imageBuffer];
//            });
            
            // 当前播放时间由AVPacket.pts字段与AVStream.time_base字段计算得出：
//            AVRational timeBase = _formatCtx->streams[_videoStream]->time_base;
//            double currentTime = pkt.pts * (double)timeBase.num / timeBase.den;
//            
//            NSLog(@"read video frame, pts: %f\n",currentTime);

//            NSDictionary *destinationImageBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
            
//            [NSNumber numberWithBool:YES],(id)kCVPixelBufferOpenGLESCompatibilityKey,nil];
            
#if 1
            KxVideoFrame *frame = [[KxVideoFrame alloc] init];
            
            if (imageBuffer) {
                
                //表示开始操作数据
//                CVPixelBufferLockBaseAddress(imageBuffer, 0);
//                
//                //图像宽度（像素）
//                size_t pixelWidth = CVPixelBufferGetWidth(imageBuffer);
//                //图像高度（像素）
//                size_t pixelHeight = CVPixelBufferGetHeight(imageBuffer);
//                //yuv中的y所占字节数
//                size_t y_size = pixelWidth * pixelHeight;
//                //yuv中的uv所占的字节数
//                size_t uv_size = y_size / 2;
//                
////                size_t v_size = y_size / 4;
//                
//                uint8_t *yuv_frame = malloc(uv_size + y_size);
//                
//                //获取CVImageBufferRef中的y数据
//                uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
//                memcpy(yuv_frame, y_frame, y_size);
//                
//                //获取CMVImageBufferRef中的uv数据
//                uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
//                memcpy(yuv_frame + y_size, uv_frame, uv_size);
                
//                CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//                CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(imageBuffer);
//                size_t length = CMBlockBufferGetDataLength(blockBufferRef);
//                Byte buffer[length];
//                CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
//                NSData *data = [NSData dataWithBytes:buffer length:length];
                
//                frame.width = _videoCodCtx->width;
//                frame.height = _videoCodCtx->height;
//                frame.position = 0.030;
//                frame.duration = 0.030;
//                frame.imageBuf = [NSData dataWithBytesNoCopy:imageBuffer length:1024*512];
//                [result addObject:frame];

                
                
//                frame = nil;

//                CFRelease(imageBuffer);
            }
#endif
            finished = YES;
//            int got_frame = 0;
            
        }
        else if (pkt.stream_index == _audioStream)
        {
 #if 1
            //Write AAC
//            fwrite(pkt.data, 1, pkt.size, fp_audes);
            
            int pktSize = pkt.size;
            
            while (pktSize > 0) {
                
                int got_frame = 0;
                // 解码音频帧，即AAC转PCM
                int len = avcodec_decode_audio4(_audioCodCtx, _audioFrame, &got_frame, &pkt);
                
                if ( len < 0 ) {
                    printf("Error in decoding a audio frame, skip!.\n");
                    continue;
                }
                
                if (got_frame > 0) {
    
                    KxAudioFrame * frame = [self handleAudioFrame];
                    if (frame) {
                        
                        [result addObject:frame];
                        
                        if (_videoStream == -1) {
                            
                            _position = frame.position;
                            decodedDuration += frame.duration;
                            if (decodedDuration > minDuration)
                                finished = YES;
                            
                        }
                    }
                    
//                    swr_convert(au_convert_ctx,
//                                &out_buffer,
//                                MAX_AUDIO_FRAME_SIZE,
//                                (const uint8_t **)audioframe->data,
//                                audioframe->nb_samples);
    
//                    if (_pcmPlay) {
//                        [_pcmPlay openAudioFromQueue:out_buffer dataSize:out_buffer_size samplerate:48000.00 channels:2 bit:16];
//                    }
    
                    //Write PCM
    //                fwrite(out_buffer, 1, out_buffer_size, fp_audes_pcm);
                    
                }
                
                if (0 == len)
                    break;
                
                pktSize -= len;
            }
#endif
        }
        
        av_free_packet(&pkt);
    }
    
    av_bitstream_filter_close(h264bsfc);
    
//    fclose(fp_vides);
//    fclose(fp_audes);
//    fclose(fp_audes_pcm);
//    avformat_close_input(&_formatCtx);
    
//    NSMutableArray *result = [NSMutableArray array];
    
    return result;
}

- (KxAudioFrame *) handleAudioFrame
{
#if 0
    if (!_audioFrame->data[0])
        return nil;
    
    id<KxAudioManager> audioManager = [KxAudioManager audioManager];
    
    const NSUInteger numChannels = audioManager.numOutputChannels;
    NSInteger numFrames;
    
    void * audioData;
    
    if (_swrContext) {
        
        const int ratio = MAX(1, audioManager.samplingRate / _audioCodCtx->sample_rate) *
        MAX(1, audioManager.numOutputChannels / _audioCodCtx->channels) * 2;
        
        const int bufSize = av_samples_get_buffer_size(NULL,
                                                       audioManager.numOutputChannels,
                                                       _audioFrame->nb_samples * ratio,
                                                       AV_SAMPLE_FMT_S16,
                                                       1);
        
        if (!_swrBuffer || _swrBufferSize < bufSize)
        {
            _swrBufferSize = bufSize;
            _swrBuffer = realloc(_swrBuffer, _swrBufferSize);
        }
        
        Byte *outbuf[2] = { _swrBuffer, 0 };
        
        numFrames = swr_convert(_swrContext,
                                outbuf,
                                _audioFrame->nb_samples * ratio,
                                (const uint8_t **)_audioFrame->data,
                                _audioFrame->nb_samples);
        
        if (numFrames < 0) {
            return nil;
        }
        
        audioData = _swrBuffer;
        
    } else {
        
        if (_audioCodCtx->sample_fmt != AV_SAMPLE_FMT_S16) {
//            NSAssert(false, @"bucheck, audio format is invalid");
            return nil;
        }
        
        audioData = _audioFrame->data[0];
        numFrames = _audioFrame->nb_samples;
    }
    
    const NSUInteger numElements = numFrames * numChannels;
    NSMutableData *data = [NSMutableData dataWithLength:numElements * sizeof(float)];
    
    float scale = 1.0 / (float)INT16_MAX ;
    vDSP_vflt16((SInt16 *)audioData, 1, data.mutableBytes, 1, numElements);
    vDSP_vsmul(data.mutableBytes, 1, &scale, data.mutableBytes, 1, numElements);
    
    KxAudioFrame *frame = [[KxAudioFrame alloc] init];
    frame.position = av_frame_get_best_effort_timestamp(_audioFrame) * _audioTimeBase;
    frame.duration = av_frame_get_pkt_duration(_audioFrame) * _audioTimeBase;
    frame.samples = data;
    
    if (frame.duration == 0) {
        // sometimes ffmpeg can't determine the duration of audio frame
        // especially of wma/wmv format
        // so in this case must compute duration
        frame.duration = frame.samples.length / (sizeof(float) * numChannels * audioManager.samplingRate);
    }
    

//    NSLog(@"AudioFrame AFD: %.4f %.4f | %.4f ",
//          frame.position,
//          frame.duration,
//          frame.samples.length / (8.0 * 44100.0));
#endif
    
    return nil;
}



#pragma mark - video decode is ffmpeg
int h264dec_decframe_ffmpeg(AVPacket avpkt, unsigned  char* h264_buffer, unsigned int frame_size, unsigned char** yuv_buffer, int *width, int* height)
{
    
#if 0
    
    int got_picture = 0;
    
//     解码一帧视频数据。输入一个压缩编码的结构体AVPacket，输出一个解码后的结构体AVFrame
    int len = avcodec_decode_video2(_videoCodCtx, _videoFrame, &got_picture, &avpkt);

    if (len < 0)
    {
         printf("Error while decoding frame %d\n", frame_size);
        return 1;
    }

    if (got_picture)
    {
        unsigned char *tmp = NULL;
        int i =0;

        if(yv12_buffer == NULL)
        {
            yv12_buffer = (unsigned char*)malloc(_videoFrame->width*_videoFrame->height*3/2);
            //            yv12_buffer = (unsigned char*)malloc(1280*720*3/2);
        }
        if(yv12_buffer==NULL)
        {
            return -1;
        }
        tmp = yv12_buffer;

        for(i=0; i<_videoFrame->height; i++)
        {
            memcpy(tmp, _videoFrame->data[0]+i*_videoFrame->linesize[0], _videoFrame->width);
            tmp+=_videoFrame->width;
        }

        for(i=0; i<_videoFrame->height/2; i++)
        {
            memcpy(tmp, _videoFrame->data[1]+i*_videoFrame->linesize[1], _videoFrame->width/2);
            tmp+=_videoFrame->width/2;
        }
        for(i=0; i<_videoFrame->height/2; i++)
        {
            memcpy(tmp, _videoFrame->data[2]+i*_videoFrame->linesize[2], _videoFrame->width/2);
            tmp+=_videoFrame->width/2;
        }

        *width = _videoFrame->width;
        *height = _videoFrame->height;
        *yuv_buffer = yv12_buffer;
    }
    else
    {
        return 1;
    }
    
#endif
    return 0;
}


#pragma mark - video decode is videotoolbox

uint8_t *_sps;
NSInteger _spsSize;
uint8_t *_pps;
NSInteger _ppsSize;
VTDecompressionSessionRef _deocderSession;
CMVideoFormatDescriptionRef _decoderFormatDescription;

typedef struct sort_queue {
    AVFrame pic;
    int serial;
    int64_t sort;
    volatile struct sort_queue *nextframe;
} sort_queue;

typedef void(^RecordDecompressionCallback)(OSStatus, VTDecodeInfoFlags, CVImageBufferRef, CMTime, CMTime);
static void decompressionCallbackStub( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef imageBuffer, CMTime presentationTimeStamp, CMTime presentationDuration )
{
    @autoreleasepool {
        
        sort_queue *newFrame    = NULL;
        
        newFrame = (sort_queue *)malloc(sizeof(sort_queue));
        memset(newFrame, 0, sizeof(sort_queue));
        
        if (!newFrame) {
            return;
        }
        
        newFrame->nextframe  = NULL;
        
        if (newFrame->pic.pts != AV_NOPTS_VALUE) {
            newFrame->sort    = newFrame->pic.pts;
        } else {
            newFrame->sort    = newFrame->pic.pkt_dts;
            newFrame->pic.pts = newFrame->pic.pkt_dts;
        }

        if (imageBuffer == NULL) {
            return;
        }
        
        OSType format_type = CVPixelBufferGetPixelFormatType(imageBuffer);
        if (format_type != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
            return;
        }
        if (kVTDecodeInfo_FrameDropped & infoFlags) {
            return;
        }
        
        if (CVPixelBufferIsPlanar(imageBuffer)) {
            newFrame->pic.width  = (int)CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
            newFrame->pic.height = (int)CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
        } else {
            newFrame->pic.width  = (int)CVPixelBufferGetWidth(imageBuffer);
            newFrame->pic.height = (int)CVPixelBufferGetHeight(imageBuffer);
        }
        
//        newFrame->pic.opaque = CVBufferRetain(imageBuffer);
//        SortQueuePush(ctx, newFrame);



//        CVPixelBufferLockBaseAddress(imageBuffer, 0);
//        uint8_t *yDestPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
//        memcpy(yDestPlane, yPlane, width * height);
//        uint8_t *uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
//        // numberOfElementsForChroma为UV宽高乘积
//        memcpy(uvDestPlane, uvPlane, numberOfElementsForChroma);
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        

        
    }
    
    ((__bridge RecordDecompressionCallback)decompressionOutputRefCon)(status, infoFlags, imageBuffer, presentationDuration, presentationDuration);
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(imageBuffer);
    
}

CVOpenGLESTextureCacheRef _textureCache;
CVOpenGLESTextureRef _texture;

static int numsss = 0;
int initH264Decoder()
{
    if(_deocderSession) {
        return 1;
    }
    
    RecordDecompressionCallback callback = ^(OSStatus status, VTDecodeInfoFlags decodeFlags, CVImageBufferRef imageBuffer, CMTime pts, CMTime ptd) {
        
        if (!status) {
            
            // 保存为UIImage
//            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
//            UIImage *uiImage = [UIImage imageWithCIImage:ciImage];
            
            //            printf("解码成功-----------！！！%d \n",status);
            //            CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly); // 可以不加
            //            if(imageBuffer) {
            //
            //                display_showfr(imageBuffer);
            //
            //            }
            
        }
        else
        {
//            NSLog(@"解码失败-----------！！！%d",status);
        }
        
    };
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        
        
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);

        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = decompressionCallbackStub;
        callBackRecord.decompressionOutputRefCon = (__bridge void *)callback;
        
        status = VTDecompressionSessionCreate(kCFAllocatorSystemDefault,
                                              _decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &_deocderSession);
        
        if(status == noErr) {
            NSLog(@"IOS8VT: Session Create success status=%d", status);
        }
        NSLog(@"status = error  IOS8VT: Session Create success status=%d", status);
        
        CFRelease(attrs);
        
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
    }
    
    return 1;
}

CVPixelBufferRef decode(const char* buffer, NSInteger size)
{
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)buffer, size,
                                                          kCFAllocatorNull,
                                                          NULL, 0, size,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr)
    {
        
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {size};
        
        status = CMSampleBufferCreateReady(kCFAllocatorMalloc,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            // kVTDecodeFrame_1xRealTimePlayback | kVTDecodeFrame_EnableAsynchronousDecompression
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
                //                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                //                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                //                NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
            }
            if (sampleBuffer != NULL)
                CFRelease(sampleBuffer);
        }
        if (blockBuffer != NULL)
            CFRelease(blockBuffer);
    }
    
    return outputPixelBuffer;
}

static const uint8_t *avc_find_startcode_internal(const uint8_t *p, const uint8_t *end)
{
    const uint8_t *a = p + 4 - ((intptr_t)p & 3);
    
    for (end -= 3; p < a && p < end; p++) {
        if (p[0] == 0 && p[1] == 0 && p[2] == 1)
            return p;
    }
    
    for (end -= 3; p < end; p += 4) {
        uint32_t x = *(const uint32_t*)p;
        //      if ((x - 0x01000100) & (~x) & 0x80008000) // little endian
        //      if ((x - 0x00010001) & (~x) & 0x00800080) // big endian
        if ((x - 0x01010101) & (~x) & 0x80808080) { // generic
            if (p[1] == 0) {
                if (p[0] == 0 && p[2] == 1)
                    return p;
                if (p[2] == 0 && p[3] == 1)
                    return p+1;
            }
            if (p[3] == 0) {
                if (p[2] == 0 && p[4] == 1)
                    return p+2;
                if (p[4] == 0 && p[5] == 1)
                    return p+3;
            }
        }
    }
    
    for (end += 3; p < end; p++) {
        if (p[0] == 0 && p[1] == 0 && p[2] == 1)
            return p;
    }
    
    return end + 3;
}

const uint8_t *avc_find_startcode(const uint8_t *p, const uint8_t *end)
{
    const uint8_t *out= avc_find_startcode_internal(p, end);
    if(p<out && out<end && !out[-1]) out--;
    return out;
}

// vodie toolbox decode
// I 帧
static BOOL _isKeyFrame = NO;

bool is_i_frame(unsigned char *tmp)
{
    if(tmp[0] == 0x00 &&
       tmp[1] == 0x00 &&
       tmp[2] == 0x00 &&
       tmp[3] == 0x01 &&
       tmp[4] == 0x67)
    {
        return 1;
    }
    else if(tmp[0] == 0x00 &&
            tmp[1] == 0x00 &&
            tmp[2] == 0x00 &&
            tmp[3] == 0x01 &&
            tmp[4] == 0x09 &&
            tmp[5] == 0x10 &&
            tmp[6] == 0x00 &&
            tmp[7] == 0x00 &&
            tmp[8] == 0x00 &&
            tmp[9] == 0x01 &&
            tmp[10] == 0x67)
    {
        return 1;
    }
    else
    {
        //	ALOGD("Skip frame");
        //	print_hex(tmp, 12);
        return 0;
    }
    return 0;
}

uint8_t *_buf_out; // 原始接收的重组数据包
//int decodeVideo(void *buffer, int buf_len)
//{
//    
//   
//    
//}
/****************************/
NSString *oldStartIndex;
NSString *oldEndIndex;
BOOL isFirstFrame;
BOOL isEndFrame;
NSOutputStream *_output;
static int ts_count = 0;
CVImageBufferRef H264decode_frame_viodeToolBox(const void *buffer, int buf_len)
{

    CVPixelBufferRef pixelBuffer = NULL;
    
    if (!_buf_out) {
        _buf_out = (uint8_t*)malloc(1024 * 1024 * sizeof(uint8_t));
    }
    
    int nal_start_num = 0;
    
    int size = buf_len - nal_start_num;// nal_start_num;
    const uint8_t *p = buffer + nal_start_num;
    const uint8_t *end = p + size;
    const uint8_t *nal_start, *nal_end;
    int nal_len, nalu_type;
    
    size = 0;
    
    nal_start = avc_find_startcode(p, end);
    
    while (![[NSThread currentThread] isCancelled]) {
        while (nal_start < end && !*(nal_start++));
        if (nal_start == end)
            break;
        
        nal_end = avc_find_startcode(nal_start, end);
        nal_len = nal_end - nal_start;
        
        nalu_type = nal_start[0] & 0x1F;
                
        if (nalu_type == 0x07) {
            if (_sps == NULL) {
                _spsSize = nal_len;
                _sps = (uint8_t*)malloc(_spsSize);
                memcpy(_sps, nal_start, _spsSize);
                
                NSLog(@"Nal type is SPS---->%s",_sps);
            }
        }
        else if (nalu_type == 0x08) {
            if (_pps == NULL) {
                _ppsSize = nal_len;
                _pps = (uint8_t*)malloc(_ppsSize);
                memcpy(_pps, nal_start, _ppsSize);
                
                NSLog(@"Nal type is PPS---->%s",_pps);
            }
        }
        else {
            
            _buf_out[size + 0] = (uint8_t)(nal_len >> 24);
            _buf_out[size + 1] = (uint8_t)(nal_len >> 16);
            _buf_out[size + 2] = (uint8_t)(nal_len >> 8 );
            _buf_out[size + 3] = (uint8_t)(nal_len);
            
            memcpy(_buf_out + 4 + size, nal_start, nal_len);
            size += 4 + nal_len;
        }
        
        nal_start = nal_end;
    }

    if(_pps != NULL && _sps != NULL)
    {
        initH264Decoder();
        _isKeyFrame = YES;
        pixelBuffer = decode((const char *)_buf_out,  size);
    }

    if (pixelBuffer) // 视频帧
        return pixelBuffer;
    
    return nil;
}

int loss_frame_test(int nalType,const uint8_t *buf)
{
    
#if 0 // test_frame
    if (!_output)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        NSString *documentsDirectory = [[paths objectAtIndex:0] stringByAppendingString:@"/"];
        NSString *filePath = [documentsDirectory stringByAppendingString:@"test2.xls"];
        
        NSOutputStream *output = [[NSOutputStream alloc] initToFileAtPath:filePath append:YES];
        [output open];
        
        _output = output;
        
    }
    
    if (_output) {
        
        if (nalType != 0x06) {
            if (nalType != 0x1e)
                ts_count ++;
        }
        
        NSString *sre;
        if (nalType == 0x1e) {
            
            NSMutableString *sre1 = [NSMutableString string];
            
            for (int i=4; i>0; i--) {
                [sre1 appendFormat:@"%02x",buf[i]];
            }
            
            sre = [NSString stringWithFormat:@"%ld",strtoul([sre1 UTF8String],0,16)];
        }
        
        if (!oldStartIndex) // first
        {
            oldStartIndex = sre;
            isFirstFrame = YES;
        }
        
        if (sre) {
            
            if (isFirstFrame || isEndFrame)
            {
                
                if (isFirstFrame) {
                    NSString *header1 = [NSString stringWithFormat:@"-----------\t-----------\t----NEXT----\t-----------\t-----------\n"];
                    
                    const uint8_t *headerString1 = (const uint8_t *)[header1 cStringUsingEncoding:NSUTF8StringEncoding];
                    NSInteger headerLength1 = [header1 lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
                    NSInteger result1 = [_output write:headerString1 maxLength:headerLength1];
                    if (result1 <= 0)
                    {
                        NSLog(@"写入错误");
                        return 1;
                    }
                }
                
                time_t timep;
                unsigned char parator = 0x09;
                //                        unsigned char new_line = 0x0A;
                timep = time((time_t *)NULL);
                
                NSString *header = [NSString stringWithFormat:@"%d%c%d%c%s%c%d\n",ts_count, parator, (int)timep, parator,[sre UTF8String], parator, (int)timep];
                
                const uint8_t *headerString = (const uint8_t *)[header cStringUsingEncoding:NSUTF8StringEncoding];
                NSInteger headerLength = [header lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
                NSInteger result = [_output write:headerString maxLength:headerLength];
                if (result <= 0) {
                    NSLog(@"写入错误");
                    return 1;
                }
                
                isFirstFrame = NO;
            }
            else
            {
                
                if ([oldStartIndex intValue] + 1 == [sre intValue])
                {
                    oldStartIndex = sre;
                    oldEndIndex = nil;
                }
                else
                {
                    oldEndIndex = sre;
                }
                
                if (oldEndIndex)
                {
                    time_t timep;
                    unsigned char parator = 0x09;
                    //                                unsigned char new_line = 0x0A;
                    timep = time((time_t *)NULL);
                    
                    NSString *header = [NSString stringWithFormat:@"%d%c%d%c%s%c%s%c%d\n",ts_count, parator, (int)timep, parator,[oldStartIndex UTF8String], parator, [oldEndIndex UTF8String],parator,(int)timep];
                    
                    const uint8_t *headerString = (const uint8_t *)[header cStringUsingEncoding:NSUTF8StringEncoding];
                    NSInteger headerLength = [header lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
                    NSInteger result = [_output write:headerString maxLength:headerLength];
                    if (result <= 0) {
                        NSLog(@"写入错误");
                        return 1;
                    }
                    
                    oldStartIndex = oldEndIndex;
                }
                
                //                        NSLog(@"-----oldStartIndex:%@  sre:%@ oldEndIndex:%@",oldStartIndex,sre, oldEndIndex);
                
            }
            
        }
        
    }
    else
    {
        return 1;
    }
#endif

    return 0;
}

#pragma mark - public API
int videoDecode(void *buffer, int buf_len)
{
    
#if DECODETYPE
   
    if (0 == H264decode_frame_viodeToolBox(buffer, buf_len)) {
        
        // 渲染显示
    }
    
#else
    
//    unsigned char *yv12_buffer = NULL;
//    int width = 0;
//    int height = 0;

//    if(0==h264dec_decframe_ffmpeg((unsigned char*)buffer,buf_len, &yv12_buffer, &width,&height))
//    {
//        display_showframe(yv12_buffer, width, height);
//    }
    
#endif
    
#ifdef DEBUG
    
#endif
    return 0;
}



@end
