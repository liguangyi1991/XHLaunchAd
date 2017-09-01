//
//  XHLaunchAd.m
//  XHLaunchAdExample
//
//  Created by zhuxiaohui on 2016/6/13.
//  Copyright © 2016年 it7090.com. All rights reserved.
//  代码地址:https://github.com/CoderZhuXH/XHLaunchAd

#import "XHLaunchAd.h"
#import "XHLaunchAdView.h"
#import "UIImageView+XHLaunchAdCache.h"
#import "NSString+XHLaunchAd.h"
#import "XHLaunchAdDownloader.h"
#import "XHLaunchAdCache.h"
#import "XHLaunchImageView.h"
#import "XHLaunchAdImage.h"
#import "XHLaunchAdController.h"

#define DISPATCH_SOURCE_CANCEL_SAFE(time) if(time)\
{\
dispatch_source_cancel(time);\
time = nil;\
}

#define REMOVE_FROM_SUPERVIEW_SAFE(view) if(view)\
{\
[view removeFromSuperview];\
view = nil;\
}

typedef NS_ENUM(NSInteger, XHLaunchAdType) {
    
    XHLaunchAdTypeImage,
    XHLaunchAdTypeVideo
};

static NSInteger defaultWaitDataDuration = 3;

@interface XHLaunchAd()

@property(nonatomic,assign)XHLaunchAdType launchAdType;
@property(nonatomic,assign)NSInteger waitDataDuration;
@property(nonatomic,strong)XHLaunchImageAdConfiguration * imageAdConfiguration;
@property(nonatomic,strong)XHLaunchVideoAdConfiguration * videoAdConfiguration;
@property(nonatomic,strong)XHLaunchAdButton * adSkipButton;
@property(nonatomic,strong)XHLaunchVideoAdView * videoAdView;
@property(nonatomic,strong)UIWindow * window;
@property(nonatomic,copy)dispatch_source_t waitDataTimer;
@property(nonatomic,copy)dispatch_source_t skipTimer;

@end

@implementation XHLaunchAd

+(void)setWaitDataDuration:(NSInteger )waitDataDuration
{
    XHLaunchAd *launchAd = [XHLaunchAd shareLaunchAd];
    launchAd.waitDataDuration = waitDataDuration;
}

+(XHLaunchAd *)imageAdWithImageAdConfiguration:(XHLaunchImageAdConfiguration *)imageAdconfiguration
{
    return [XHLaunchAd imageAdWithImageAdConfiguration:imageAdconfiguration delegate:nil];
}

+(XHLaunchAd *)imageAdWithImageAdConfiguration:(XHLaunchImageAdConfiguration *)imageAdconfiguration delegate:(id)delegate;
{
    XHLaunchAd *launchAd = [XHLaunchAd shareLaunchAd];
    if(delegate) launchAd.delegate = delegate;
    launchAd.imageAdConfiguration = imageAdconfiguration;
    return launchAd;
}
+(XHLaunchAd *)videoAdWithVideoAdConfiguration:(XHLaunchVideoAdConfiguration *)videoAdconfiguration
{
    return [XHLaunchAd videoAdWithVideoAdConfiguration:videoAdconfiguration delegate:nil];
}
+(XHLaunchAd *)videoAdWithVideoAdConfiguration:(XHLaunchVideoAdConfiguration *)videoAdconfiguration delegate:(nullable id)delegate;
{
    XHLaunchAd *launchAd = [XHLaunchAd shareLaunchAd];
    if(delegate) launchAd.delegate = delegate;
    launchAd.videoAdConfiguration = videoAdconfiguration;
    return launchAd;
}
+(void)downLoadImageAndCacheWithURLArray:(NSArray <NSURL *> * )urlArray
{
    if(urlArray.count==0) return;
    [[XHLaunchAdDownloader sharedDownloader] downLoadImageAndCacheWithURLArray:urlArray];
}
+(void)downLoadVideoAndCacheWithURLArray:(NSArray <NSURL *> * )urlArray
{
    if(urlArray.count==0) return;
    [[XHLaunchAdDownloader sharedDownloader] downLoadVideoAndCacheWithURLArray:urlArray];
}
+(void)skipAction
{
    [[XHLaunchAd shareLaunchAd] adSkipButtonClick];
}
+(BOOL)checkImageInCacheWithURL:(NSURL *)url
{
    return [XHLaunchAdCache checkImageInCacheWithURL:url];
}

+(BOOL)checkVideoInCacheWithURL:(NSURL *)url
{
    return [XHLaunchAdCache checkVideoInCacheWithURL:url];
}
+(void)clearDiskCache
{
    [XHLaunchAdCache clearDiskCache];
}

+(float)diskCacheSize
{
    return [XHLaunchAdCache diskCacheSize];
}
+(NSString *)xhLaunchAdCachePath
{
    return [XHLaunchAdCache xhLaunchAdCachePath];
}
+(NSString *)cacheImageURLString
{
    return [XHLaunchAdCache getCacheImageUrl];
}
+(NSString *)cacheVideoURLString
{
    return [XHLaunchAdCache getCacheVideoUrl];
}
#pragma mark - private
+(XHLaunchAd *)shareLaunchAd{
    
    static XHLaunchAd *instance = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken,^{
        
        instance = [[XHLaunchAd alloc] init];
    });
    return instance;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self setupLaunchAd];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            
            [self setupLaunchAdEnterForeground];
            
        }];
        
    }
    return self;
}

-(void)setupLaunchAdEnterForeground
{
    switch (_launchAdType) {
            case XHLaunchAdTypeImage:
        {
            if(!_imageAdConfiguration.showEnterForeground) return;
            [self setupLaunchAd];
            [self setupImageAdForConfiguration:_imageAdConfiguration];
        }
            break;
            case XHLaunchAdTypeVideo:
        {
            if(!_videoAdConfiguration.showEnterForeground) return;
            [self setupLaunchAd];
            [self setupVideoAdForConfiguration:_videoAdConfiguration];
        }
            break;
        default:
            break;
    }
}
-(void)setupLaunchAd
{
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = [XHLaunchAdController new];
    window.rootViewController.view.backgroundColor = [UIColor clearColor];
    window.rootViewController.view.userInteractionEnabled = NO;
    window.windowLevel = UIWindowLevelStatusBar + 1;
    window.hidden = NO;
    window.alpha = 1;
    _window = window;
    
    /** 添加launchImageView */
    [_window addSubview:[[XHLaunchImageView alloc] init]];
}

/**图片*/
-(void)setupImageAdForConfiguration:(XHLaunchImageAdConfiguration *)configuration
{
    [self removeSubViewsExceptLaunchAdImageView];
    
    XHLaunchImageAdView *imageAdView = [[XHLaunchImageAdView alloc] init];
    [_window addSubview:imageAdView];
    /** frame */
    if(configuration.frame.size.width>0 && configuration.frame.size.height>0) imageAdView.frame = configuration.frame;
    if(configuration.contentMode) imageAdView.contentMode = configuration.contentMode;
    /** webImage */
    if(configuration.imageNameOrURLString.length && configuration.imageNameOrURLString.xh_isURLString)
    {
        [XHLaunchAdCache async_saveImageUrl:configuration.imageNameOrURLString];
        /** 自设图片 */
        if ([self.delegate respondsToSelector:@selector(xhLaunchAd:launchAdImageView:URL:)]) {
            
            [self.delegate xhLaunchAd:self launchAdImageView:imageAdView URL:[NSURL URLWithString:configuration.imageNameOrURLString]];
        }
        else
        {
            if(!configuration.imageOption) configuration.imageOption = XHLaunchAdImageDefault;
            __weak typeof(self) weakSelf = self;
            [imageAdView xh_setImageWithURL:[NSURL URLWithString:configuration.imageNameOrURLString] placeholderImage:nil options:configuration.imageOption completed:^(UIImage *image,NSData *imageData,NSError *error,NSURL *url){
                
                if ([weakSelf.delegate respondsToSelector:@selector(xhLaunchAd:imageDownLoadFinish:)]) {
                    [weakSelf.delegate xhLaunchAd:self imageDownLoadFinish:image];
                }
            }];
            
            if(configuration.imageOption == XHLaunchAdImageCacheInBackground){
                /** 缓存中未有 */
                if(![XHLaunchAdCache checkImageInCacheWithURL:[NSURL URLWithString:configuration.imageNameOrURLString]]){
                    [self removeAndAnimateDefault]; return; /** 完成显示 */
                }
            }
        }
    }
    else{
        
        if(configuration.imageNameOrURLString.length){
            
            UIImage *image = [XHLaunchAdImage imageNamed:configuration.imageNameOrURLString];
            
            if(image){
                
                if ([self.delegate respondsToSelector:@selector(xhLaunchAd:imageDownLoadFinish:)]) {
                    
                    [self.delegate xhLaunchAd:self imageDownLoadFinish:image];
                }
                
                imageAdView.image = image;
                
            }else{
                
                NSLog(@"Error:广告图片未找到,请检查名称是否有误!");
            }
            
        }else{
            NSLog(@"未设置广告图片");
        }
        
    }
    
    [self startSkipDispathTimer];
    
    /** skipButton */
    [self addSkipButtonForConfiguration:configuration];
    
    /** customView */
    if(configuration.subViews.count>0)  [self addSubViews:configuration.subViews];
    
    __weak typeof(self) weakSelf = self;
    imageAdView.adClick = ^()
    {
        [weakSelf adClickAction];
    };
    
}

-(void)addSkipButtonForConfiguration:(XHLaunchAdConfiguration *)configuration
{
    if(!configuration.duration) configuration.duration = 5;
    if(!configuration.skipButtonType) configuration.skipButtonType = SkipTypeTimeText;
    
    if(configuration.customSkipView)
    {
        [_window addSubview:configuration.customSkipView];
    }
    else
    {
        if(_adSkipButton == nil)
        {
            _adSkipButton = [[XHLaunchAdButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-80,20, 70, 35)];
            _adSkipButton.hidden = YES;
            [_adSkipButton addTarget:self action:@selector(adSkipButtonClick) forControlEvents:UIControlEventTouchUpInside];
            _adSkipButton.leftRightSpace = 5;
            _adSkipButton.topBottomSpace = 2.5;
            
        }
        [_window addSubview:_adSkipButton];
        [_adSkipButton stateWithSkipType:configuration.skipButtonType andDuration:configuration.duration];
    }
}

/**视频*/
-(void)setupVideoAdForConfiguration:(XHLaunchVideoAdConfiguration *)configuration
{
    [self removeSubViewsExceptLaunchAdImageView];
    
    if(_videoAdView == nil)
    {
        _videoAdView = [[XHLaunchVideoAdView alloc] init];
    }
    [_window addSubview:_videoAdView];
    /** frame */
    if(configuration.frame.size.width>0&&configuration.frame.size.height>0) _videoAdView.frame = configuration.frame;
    if(configuration.scalingMode) _videoAdView.adVideoScalingMode = configuration.scalingMode;
    /** video 数据源 */
    if(configuration.videoNameOrURLString.length && configuration.videoNameOrURLString.xh_isURLString){
        
        [XHLaunchAdCache async_saveVideoUrl:configuration.videoNameOrURLString];
        
        NSURL *pathURL = [XHLaunchAdCache getCacheVideoWithURL:[NSURL URLWithString:configuration.videoNameOrURLString]];
        if(pathURL){
            if ([self.delegate respondsToSelector:@selector(xhLaunchAd:videoDownLoadFinish:)]) {
                [self.delegate xhLaunchAd:self videoDownLoadFinish:pathURL];
            }
            _videoAdView.adVideoPlayer.contentURL = pathURL;
            [_videoAdView.adVideoPlayer prepareToPlay];
            
        }else{
            
            __weak typeof(self) weakSelf = self;
            [[XHLaunchAdDownloader sharedDownloader] downloadVideoWithURL:[NSURL URLWithString:configuration.videoNameOrURLString] progress:^(unsigned long long total, unsigned long long current) {
                
                if ([weakSelf.delegate respondsToSelector:@selector(xhLaunchAd:videoDownLoadProgress:total:current:)]) {
                    [weakSelf.delegate xhLaunchAd:self videoDownLoadProgress:current/(float)total total:total current:current];
                }
                
            }  completed:^(NSURL * _Nullable location, NSError * _Nullable error){
                
                if ([weakSelf.delegate respondsToSelector:@selector(xhLaunchAd:videoDownLoadFinish:)]){
                    [weakSelf.delegate xhLaunchAd:self videoDownLoadFinish:location];
                }
            }];
            
            /***视频缓存,提前显示完成 */
            [self removeAndAnimateDefault]; return;
        }
    }
    else
    {
        if(configuration.videoNameOrURLString.length){
            
            NSString *path = [[NSBundle mainBundle]pathForResource:configuration.videoNameOrURLString ofType:nil];
            if(path.length){
                NSURL *pathURL = [NSURL fileURLWithPath:path];
                if ([self.delegate respondsToSelector:@selector(xhLaunchAd:videoDownLoadFinish:)]) {
                    [self.delegate xhLaunchAd:self videoDownLoadFinish:pathURL];
                }
                _videoAdView.adVideoPlayer.contentURL = pathURL;;
                [_videoAdView.adVideoPlayer prepareToPlay];
                
            }else{
                NSLog(@"Error:广告视频未找到,请检查名称是否有误!");
            }
        }else{
            NSLog(@"未设置广告视频");
        }
    }
    
    [self startSkipDispathTimer];
    
    /** skipButton */
    [self addSkipButtonForConfiguration:configuration];
    
    /** customView */
    if(configuration.subViews.count>0) [self addSubViews:configuration.subViews];
    
    __weak typeof(self) weakSelf = self;
    _videoAdView.adClick = ^()
    {
        [weakSelf adClickAction];
    };
}
#pragma mark - add subViews
-(void)addSubViews:(NSArray *)subViews
{
    [subViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        
        [_window addSubview:view];
    }];
}
#pragma mark - set
-(void)setImageAdConfiguration:(XHLaunchImageAdConfiguration *)imageAdConfiguration
{
    _imageAdConfiguration = imageAdConfiguration;
    _launchAdType = XHLaunchAdTypeImage;
    [self setupImageAdForConfiguration:imageAdConfiguration];
}
-(void)setVideoAdConfiguration:(XHLaunchVideoAdConfiguration *)videoAdConfiguration
{
    _videoAdConfiguration = videoAdConfiguration;
    _launchAdType = XHLaunchAdTypeVideo;
    [self setupVideoAdForConfiguration:videoAdConfiguration];
}
-(void)setWaitDataDuration:(NSInteger)waitDataDuration
{
    _waitDataDuration = waitDataDuration;
    /** 数据等待 */
    [self startWaitDataDispathTiemr];
}
#pragma mark - Action
-(void)adSkipButtonClick
{
    [self removeAndAnimate];
}
-(void)adClickAction
{
    XHLaunchAdConfiguration * configuration = [self commonConfiguration];
    
    if ([self.delegate respondsToSelector:@selector(xhLaunchAd:clickAndOpenURLString:)] && configuration.openURLString.length) {
        
        [self.delegate xhLaunchAd:self clickAndOpenURLString:configuration.openURLString];
        
        [self removeAndAnimateDefault];
    }
    
}

-(XHLaunchAdConfiguration *)commonConfiguration
{
    XHLaunchAdConfiguration *configuration = nil;
    switch (_launchAdType) {
            case XHLaunchAdTypeVideo:
            configuration = _videoAdConfiguration;
            break;
            case XHLaunchAdTypeImage:
            configuration = _imageAdConfiguration;
            break;
        default:
            break;
    }
    return configuration;
}
-(void)startWaitDataDispathTiemr
{
    __block NSInteger duration = defaultWaitDataDuration;
    if(_waitDataDuration) duration = _waitDataDuration;
    NSTimeInterval period = 1.0;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _waitDataTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_waitDataTimer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_waitDataTimer, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(duration==0)
            {
                DISPATCH_SOURCE_CANCEL_SAFE(_waitDataTimer);
                [self removeAndAnimateDefault]; return ;
            }
            duration--;
        });
    });
    
    dispatch_resume(_waitDataTimer);
}

-(void)startSkipDispathTimer
{
    XHLaunchAdConfiguration * configuration = [self commonConfiguration];
    DISPATCH_SOURCE_CANCEL_SAFE(_waitDataTimer);
    if(!configuration.skipButtonType) configuration.skipButtonType = SkipTypeTimeText;//默认
    __block NSInteger duration = 5;//默认
    if(configuration.duration) duration = configuration.duration;
    NSTimeInterval period = 1.0;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _skipTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_skipTimer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_skipTimer, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([self.delegate respondsToSelector:@selector(xhLaunchAd:customSkipView:duration:)]) {
                
                [self.delegate xhLaunchAd:self customSkipView:configuration.customSkipView duration:duration];
            }
            if(!configuration.customSkipView)
            {
                [_adSkipButton stateWithSkipType:configuration.skipButtonType andDuration:duration];
            }
            if(duration==0)
            {
                DISPATCH_SOURCE_CANCEL_SAFE(_skipTimer);
                [self removeAndAnimate]; return ;
            }
            duration--;
        });
    });
    
    dispatch_resume(_skipTimer);
}

-(void)removeAndAnimate{
    
    XHLaunchAdConfiguration * configuration = [self commonConfiguration];
    
    if(!configuration.showFinishAnimate) configuration.showFinishAnimate = ShowFinishAnimateFadein;
    
    if(configuration.showFinishAnimate == ShowFinishAnimateLite)
    {
        CGFloat duration = showFinishAnimateTimeDefault;
        if(configuration.showFinishAnimateTime>0) duration = configuration.showFinishAnimateTime;
        [UIView animateWithDuration:duration animations:^{
            
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            _window.transform=CGAffineTransformMakeScale(2.f, 2.f);
            _window.alpha = 0;
        } completion:^(BOOL finished) {
            [self remove];
        }];
    }
    else if(configuration.showFinishAnimate == ShowFinishAnimateFadein)
    {
        CGFloat duration = showFinishAnimateTimeDefault;
        if(configuration.showFinishAnimateTime>0) duration = configuration.showFinishAnimateTime;
        [UIView animateWithDuration:duration animations:^{
            _window.alpha = 0;
        } completion:^(BOOL finished) {
            [self remove];
        }];
    }
    else
    {
        [self remove];
    }
}

-(void)remove{
    
    DISPATCH_SOURCE_CANCEL_SAFE(_waitDataTimer)
    DISPATCH_SOURCE_CANCEL_SAFE(_skipTimer)
    REMOVE_FROM_SUPERVIEW_SAFE(_adSkipButton)
    if(_launchAdType==XHLaunchAdTypeVideo)
    {
        if(_videoAdView==nil) return;
        [_videoAdView stopVideoPlayer];
        REMOVE_FROM_SUPERVIEW_SAFE(_videoAdView)
    }
    
    [_window.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        REMOVE_FROM_SUPERVIEW_SAFE(obj)
    }];
    _window.hidden = YES;
    _window = nil;
    if ([self.delegate respondsToSelector:@selector(xhLaunchShowFinish:)]) {
        
        [self.delegate xhLaunchShowFinish:self];
    }
}
-(void)removeAndAnimateDefault
{
    [UIView animateWithDuration:0.3 animations:^{
        _window.alpha = 0;
    } completion:^(BOOL finished) {
        [self remove];
    }];
}
-(void)removeSubViewsExceptLaunchAdImageView
{
    [_window.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if(![obj isKindOfClass:[XHLaunchImageView class]])
        {
            REMOVE_FROM_SUPERVIEW_SAFE(obj)
        }
    }];
    
}
@end
