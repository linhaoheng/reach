#import <UIKit/UIKit.h>
#import "MediaRemote.h"
#define plistPath @"/var/jb/var/mobile/Library/Preferences/com.lhh.reachplayerprefs.plist"
// 定义通知名称，用于重新加载偏好设置
static NSString *preferencesNotification = @"com.lhh.reachplayerprefs/ReloadPrefs";
BOOL isFromCustomGesture = NO;  // 添加这行
BOOL enable, enableGesture;
double keepAliveDuration, reachOffset;

static void loadPreferences() {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    enable = dict[@"enable"] ? [dict[@"enable"] boolValue] : YES;
    enableGesture = dict[@"enableGesture"] ? [dict[@"enableGesture"] boolValue] : YES;
    keepAliveDuration = dict[@"keepAliveDuration"] ? [dict[@"keepAliveDuration"] doubleValue] : 1800;
    reachOffset = dict[@"reachOffset"] ? [dict[@"reachOffset"] doubleValue] : 0.3;
}

// SBLockScreenManager类声明
@interface SBLockScreenManager : NSObject
// 获取单例实例
+(id)sharedInstance;
@end



// ReachPlayerArtworkContainerView类声明
@interface ReachPlayerArtworkContainerView : UIView
@property (nonatomic, strong) UIImageView *artworkView;      // 艺术品视图
@end


//ReachPlayerContainerView类声明
@interface ReachPlayerContainerView : UIView
@property (nonatomic, retain) UIImageView *backgroundImageView;      // 背景图片视图
@property (nonatomic, retain) ReachPlayerArtworkContainerView *artworkContainerView; // 艺术品容器视图
@property (nonatomic, retain) UILabel *nowPlayingInfoSong;           // 当前播放歌曲标签
@property (nonatomic, retain) UILabel *nowPlayingInfoArtist;         // 当前播放艺术家标签
@property (nonatomic, retain) UILabel *nowPlayingInfoAlbum;          // 当前播放专辑标签
@property (nonatomic, retain) UIButton *playPauseButton;             // 播放/暂停按钮
@property (nonatomic, retain) UIButton *nextButton;                  // 下一首按钮
@property (nonatomic, retain) UIButton *previousButton;              // 上一首按钮
@end


// SBWallpaperEffectView类声明(继承自UIVisualEffectView)
@interface SBWallpaperEffectView : UIVisualEffectView
@end

// SBReachabilityBackgroundView类声明
@interface SBReachabilityBackgroundView : UIView
@end

// SBReachabilityBackgroundViewController类声明
@interface SBReachabilityBackgroundViewController : UIViewController
@property (nonatomic, retain) NSTimer *updateTimer;                // 更新定时器
// 更新Reachability状态
- (void)updateReachability;
// 添加ReachPlayerContainerView视图
- (void)addReachPlayerContainerView;
@end

// UIColor扩展(私有方法)
@interface UIColor (Private)
// 判断颜色是否与指定颜色相似(在给定百分比范围内)
-(BOOL)_isSimilarToColor:(id)arg1 withinPercentage:(double)arg2 ;
@end

// SBReachabilityManager类声明
@interface SBReachabilityManager : NSObject
// 设置保持活跃定时器
-(void)_setKeepAliveTimer;
// 获取单例实例
+(id)sharedInstance;
// 切换Reachability状态
-(void)toggleReachability;
// 判断Reachability模式是否激活
-(BOOL)reachabilityModeActive;
// 停用Reachability
-(void)deactivateReachability;
// 通知观察者Reachability Y偏移量变化
-(void)_notifyObserversReachabilityYOffsetDidChange;
@end

// SBMediaController类声明
@interface SBMediaController
// 获取单例实例
+ (id)sharedInstance;
// 判断是否正在播放
- (BOOL)isPlaying;
//- (void)setNowPlayingInfo:(int)arg1;
@end

// SBReachabilityWindow类声明
@interface SBReachabilityWindow : UIWindow
// 获取视图
- (id)view;
@end

// SBHomeScreenSpotlightViewController类声明
@interface SBHomeScreenSpotlightViewController : UIViewController
@end

// _UIStatusBarForegroundView类声明
@interface _UIStatusBarForegroundView : UIView
// 切换状态栏Reachability状态
- (void)toggleStatusReachability:(id)sender;
@end

