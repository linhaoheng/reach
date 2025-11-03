#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import "MediaRemote.h"
#import "UIColor+Hex.h"
#import <CoreText/CoreText.h>//自定义字体
#import "LHHNowPlayingProgressView.h"
#import "public/MSHFJelloView.h"

static NSString *preferencesNotification = @"com.lhh.reachplayerprefs/ReloadPrefs";

#define bundlePath @"/var/jb/Library/PreferenceBundles/reachplayerprefs.bundle/"
// 子目录路径
#define presetThemesPath [bundlePath stringByAppendingPathComponent:@"PresetThemes/"]
#define plistPath @"/var/jb/var/mobile/Library/Preferences/com.lhh.reachplayerprefs.plist"

BOOL albumCircleView, albumRotating, AlignmentCenter, showOverlay, cover, Vibration, myfont, Progress, snowEnabled, enablemshf, EnableFFT, DisableBatterySaver;//圆形，转动，布局，唱片，封面，震动，自定义字体
double positionXRP, positionYRP, artworkSizeRP, reachOffsetRP, albumArtworkViewX, albumArtworkViewY, baseRotationSpeed, tonearmViewX, tonearmViewY, fontOfSize, tagLengthRP, spac, lyricsLabelX, lyricsLabelY, buttonSize, buttonSpacing, buttonOffsetX, buttonOffsetY, progresswidth, progressX, progressY, FontOfSize, ToConstant, numSnowflakes, selfFlake, snowvelocity, snowlifetime, snowheight, snowwidth, numberOfPoints, WaveOffset, Fps, Sensitivity, Gain, Limiter, widthmshf, waveOffsetX;//整体水平位置，整体垂直位置，专辑大小，图片高度，专辑水平位置，专辑垂直位置，转速，唱针水平位置，唱针垂直位置，歌词大小
NSString *textColor;
NSString *elapsedColor;
NSString *remainingColor;
NSString *knobColor;
NSString *elapsedLabelColor;
NSString *remainingLabelColor;
NSString *WaveColor;
static void loadPreferences() {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plistPath];

    albumCircleView = dict[@"albumCircleView"] ? [dict[@"albumCircleView"] boolValue] : YES;//圆形
    showOverlay = dict[@"showOverlay"] ? [dict[@"showOverlay"] boolValue] : YES;//唱片
    albumRotating = dict[@"albumRotating"] ? [dict[@"albumRotating"] boolValue] : YES;//旋转
    cover = dict[@"cover"] ? [dict[@"cover"] boolValue] : NO;//自定义专辑
    AlignmentCenter = dict[@"AlignmentCenter"] ? [dict[@"AlignmentCenter"] boolValue] : YES;//歌词居中
    myfont = dict[@"myfont"] ? [dict[@"myfont"] boolValue] : NO;//自定义字体
    Vibration = dict[@"Vibration"] ? [dict[@"Vibration"] boolValue] : YES;//震动
    Progress = dict[@"Progress"] ? [dict[@"Progress"] boolValue] : YES;//进度条
    
    
    snowEnabled = dict[@"snowEnabled"] ? [dict[@"snowEnabled"] boolValue] : YES;//粒子
    baseRotationSpeed = dict[@"baseRotationSpeed"] ? [dict[@"baseRotationSpeed"] doubleValue] : 6;//转动速度
    tonearmViewX = dict[@"tonearmViewX"] ? [dict[@"tonearmViewX"] doubleValue] : 15;//唱针水平位置
    tonearmViewY = dict[@"tonearmViewY"] ? [dict[@"tonearmViewY"] doubleValue] : 0;
    positionXRP = dict[@"positionX"] ? [dict[@"positionX"] doubleValue] : 0;//整体水平位置
    positionYRP = dict[@"positionY"] ? [dict[@"positionY"] doubleValue] : 160;
    albumArtworkViewX = dict[@"albumArtworkViewX"] ? [dict[@"albumArtworkViewX"] doubleValue] : -45;//专辑水平位置
    albumArtworkViewY = dict[@"albumArtworkViewY"] ? [dict[@"albumArtworkViewY"] doubleValue] : 0;
    artworkSizeRP = dict[@"artworkSize"] ? [dict[@"artworkSize"] doubleValue] : 100.0;//专辑大小
    reachOffsetRP = dict[@"reachOffsetRP"] ? [dict[@"reachOffsetRP"] doubleValue] : 200;//图片高度
    fontOfSize = dict[@"fontOfSize"] ? [dict[@"fontOfSize"] doubleValue] : 20;//字体大小
    tagLengthRP = dict[@"tagLengthRP"] ? [dict[@"tagLengthRP"] doubleValue] : 200;//歌词宽度
    spac = dict[@"spac"] ? [dict[@"spac"] doubleValue] : 5;
    lyricsLabelX = dict[@"lyricsLabelX"] ? [dict[@"lyricsLabelX"] doubleValue] : 0;//歌词水平位置
    lyricsLabelY = dict[@"lyricsLabelY"] ? [dict[@"lyricsLabelY"] doubleValue] : -10;//歌词垂直位置
    buttonSize = dict[@"buttonSize"] ? [dict[@"buttonSize"] doubleValue] : 40;//按钮大小
    buttonSpacing = dict[@"buttonSpacing"] ? [dict[@"buttonSpacing"] doubleValue] : 100;//按钮间距
    buttonOffsetX = dict[@"buttonOffsetX"] ? [dict[@"buttonOffsetX"] doubleValue] : -70;//按钮水平位置
    buttonOffsetY = dict[@"buttonOffsetY"] ? [dict[@"buttonOffsetY"] doubleValue] : 50;//按钮垂直位置
    progressX = dict[@"progressX"] ? [dict[@"progressX"] doubleValue] : 75;//进度条水平位置
    progressY = dict[@"progressY"] ? [dict[@"progressY"] doubleValue] : 75;//进度条垂直位置
    progresswidth = dict[@"progresswidth"] ? [dict[@"progresswidth"] doubleValue] : 170;//进度条宽度
    FontOfSize = dict[@"FontOfSize"] ? [dict[@"FontOfSize"] doubleValue] : 13;//进度条字体大小
    ToConstant = dict[@"ToConstant"] ? [dict[@"ToConstant"] doubleValue] : 3;//进度条高度
    numSnowflakes = dict[@"numSnowflakes"] ? [dict[@"numSnowflakes"] doubleValue] : 30;//粒子数量
    selfFlake = dict[@"selfFlake"] ? [dict[@"selfFlake"] doubleValue] : 0.25;//粒子大小
    snowvelocity = dict[@"snowvelocity"] ? [dict[@"snowvelocity"] doubleValue] : 30;//粒子下落速度
    snowlifetime = dict[@"snowlifetime"] ? [dict[@"snowlifetime"] doubleValue] : 30;//粒子存在时间
    snowheight = dict[@"snowheight"] ? [dict[@"snowheight"] doubleValue] : 530;//粒子初始位置
    
    textColor = dict[@"textColor"] ?: @"#FFFFFF";//歌词颜色
    elapsedColor = dict[@"elapsedColor"] ?: @"#275FF4";
    remainingColor = dict[@"remainingColor"] ?: @"#d3d3d3";
    knobColor = dict[@"knobColor"] ?: @"#EB4D3D";
    elapsedLabelColor = dict[@"elapsedLabelColor"] ?: @"#000000";
    remainingLabelColor = dict[@"remainingLabelColor"] ?: @"#000000";
    
    enablemshf = dict[@"enablemshf"] ? [dict[@"enablemshf"] boolValue] : YES;
    EnableFFT = dict[@"EnableFFT"] ? [dict[@"EnableFFT"] boolValue] : YES;
    numberOfPoints = dict[@"numberOfPoints"] ? [dict[@"numberOfPoints"] doubleValue] : 16;
    WaveColor = dict[@"WaveColor"] ?: @"#EAEAEA";
    WaveOffset = dict[@"WaveOffset"] ? [dict[@"WaveOffset"] doubleValue] : -111;
    Fps = dict[@"Fps"] ? [dict[@"Fps"] doubleValue] : 24;
    Sensitivity = dict[@"Sensitivity"] ? [dict[@"Sensitivity"] doubleValue] : 1.0;
    Gain = dict[@"Gain"] ? [dict[@"Gain"] doubleValue] : 100;
    Limiter = dict[@"Limiter"] ? [dict[@"Limiter"] doubleValue] : 0;
    DisableBatterySaver = dict[@"DisableBatterySaver"] ? [dict[@"DisableBatterySaver"] boolValue] : NO;
    widthmshf = dict[@"widthmshf"] ? [dict[@"widthmshf"] doubleValue] : 280;
    waveOffsetX = dict[@"waveOffsetX"] ? [dict[@"waveOffsetX"] doubleValue] : 0;
}

// 扩展UILabel类，添加跑马灯效果相关的方法
@interface UILabel (RP)
- (void)setMarqueeRunning:(BOOL)arg1;
- (void)setMarqueeEnabled:(BOOL)arg1;
- (BOOL)marqueeEnabled;
- (BOOL)marqueeRunning;
@end
// 声明ReachPlayerArtworkContainerView类，用于显示专辑封面
@interface ReachPlayerArtworkContainerView : UIView
@property (nonatomic, strong) UIImageView *artworkView;
@end

@implementation ReachPlayerArtworkContainerView
@end

@interface ReachPlayerContainerView : UIView
@property (nonatomic, strong) UIView *snowView;
@property (nonatomic, strong) LHHNowPlayingProgressView *progressView;
@property (nonatomic, strong) NSString *customFontName;//自定义字体
@property (nonatomic, strong) UIImageView *tonearmlayView;//唱针
@property (nonatomic, retain) UIImageView *backgroundImageView;//背景图片
@property (nonatomic, retain) ReachPlayerArtworkContainerView *artworkContainerView;// 专辑封面容器视图
@property (nonatomic, retain) UILabel *nowPlayingInfoSong;// 歌曲名称标签
@property (nonatomic, retain) UILabel *nowPlayingInfoArtist;// 艺术家名称标签
@property (nonatomic, retain) UILabel *nowPlayingInfoAlbum;// 专辑名称标签
@property (nonatomic, retain) UIStackView *labelsStackView; // 标签堆栈视图
@property (nonatomic, retain) UIButton *playPauseButton;// 播放/暂停按钮
@property (nonatomic, retain) UIButton *nextButton;// 下一首按钮
@property (nonatomic, retain) UIButton *previousButton;// 上一首按钮
@property (nonatomic, retain) UIStackView *controlsStackView;// 控制按钮堆栈视图
- (void)addBackgroundImage;
- (void)addArtworkContainerView;// 添加专辑封面容器
- (void)addNowPlayingInfoSong;// 添加歌曲名称标签
- (void)addNowPlayingInfoAlbum;// 添加专辑名称标签
- (void)addPlayPauseButton;// 添加播放/暂停按钮
- (void)addNextButton;// 添加下一首按钮
- (void)addPreviousButton;// 添加上一首按钮
- (void)playingDidChange:(NSNotification *)notification;// 播放状态变更处理
- (void)updateTransition; // 更新过渡动画
- (void)playPause;// 播放/暂停操作
- (void)next;// 下一首操作
- (void)previous;// 上一首操作
- (void)updateImage;// 更新图片（专辑封面）
- (void)addLabelsStackView;// 添加标签堆栈视图
- (void)addControlsStackView;// 添加控制按钮堆栈视图
@end
//四个旋转方法，三个标签，按钮动画
@interface ReachPlayerContainerView ()
{
    CAEmitterLayer *_snowEmitterLayer;
}
@property(strong, nonatomic) MSHFJelloView *mshfView;
@property (nonatomic, assign) BOOL isAnimating;//四个专辑旋转
@property (nonatomic, assign) BOOL isStopping;
@property (nonatomic, assign) CGFloat currentRotationAngle;
@property (nonatomic, copy) dispatch_block_t pendingStopBlock;
@property (nonatomic, strong) NSString *currentSongTitle;//三个标签
@property (nonatomic, strong) NSString *currentArtist;
@property (nonatomic, strong) NSString *currentAlbum;
- (void)buttonTouchDown:(UIButton *)button;
- (void)buttonTouchUp:(UIButton *)button;
@end


@interface UIApplication (Private)
- (void)launchApplicationWithIdentifier:(NSString *)identifier suspended:(BOOL)suspended;
@end

//启动播放应用
typedef void (^MRMediaRemoteGetNowPlayingClientBlock)(id client);
extern "C" void MRMediaRemoteGetNowPlayingClient(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingClientBlock block);
extern "C" NSString *MRNowPlayingClientGetBundleIdentifier(id client);
extern "C" NSString *MRNowPlayingClientGetParentAppBundleIdentifier(id client);

@interface SBReachabilityManager : NSObject
+(id)sharedInstance;
// 停用Reachability
-(void)deactivateReachability;
@end
