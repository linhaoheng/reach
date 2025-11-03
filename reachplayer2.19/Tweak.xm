#import "Tweak.h"

// 全局视图变量
UIView *emptyView;
ReachPlayerContainerView *containerView;

%group ReachPlayer

// 对状态栏前景视图的hook，添加双击手势
%hook _UIStatusBarForegroundView
// 双击状态栏激活Reachability
- (id)initWithFrame:(CGRect)frame {
    self = %orig;
    // 添加双击手势识别器到状态栏
    if (enableGesture) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleStatusReachability:)];
        self.userInteractionEnabled = YES;
        tapGesture.numberOfTapsRequired = 1;  // 需要双击
        [self addGestureRecognizer:tapGesture];
    }
    

    return self;
}

// 新方法处理状态栏双击
%new
- (void)toggleStatusReachability:(id)sender {
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
        if (!result) return; // 没有任何播放信息
        NSDictionary *nowPlayingInfo = (__bridge NSDictionary *)result;
        NSString *title = nowPlayingInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle];
        // 检查是否有歌曲标题，表示有音乐正在播放
        if (title != nil) {
            isFromCustomGesture = YES;
            [[%c(SBReachabilityManager) sharedInstance] toggleReachability];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                isFromCustomGesture = NO;
            });
        }
    }); // 如果没有音乐播放，什么都不做
}
%end



// 禁用Spotlight搜索当Reachability激活时
%hook SBSearchScrollView
-(bool) gestureRecognizerShouldBegin:(id)arg1 {
    if ([[%c(SBReachabilityManager) sharedInstance] reachabilityModeActive] == YES) {
        return NO;  // 阻止手势开始
    }
    return %orig;
}

// 禁用Spotlight搜索当Reachability激活时
-(BOOL)gestureRecognizer:(id)arg1 shouldRequireFailureOfGestureRecognizer:(id)arg2 {
    if ([[%c(SBReachabilityManager) sharedInstance] reachabilityModeActive] == YES) {
        return NO;  // 阻止手势失败要求
    }
    return %orig;
}
%end

// Reachability设置相关hook
%hook SBReachabilitySettings
-(double)yOffsetFactor {
    return reachOffset;  // 返回垂直偏移量
}

// 设置垂直偏移量
- (void)setYOffsetFactor:(double)arg1 {
    %orig(reachOffset);
}

// 支持所有设备
- (bool)allowOnAllDevices {
    return YES;
}

// 支持所有设备
- (void)setAllowOnAllDevices:(bool)arg1 {
    %orig(YES);
}
%end

// Reachability管理器hook
%hook SBReachabilityManager
// 修改保活计时器行为
-(void)_pingKeepAliveWithDuration:(double)arg1 interactedBeforePing:(BOOL)arg2 initialKeepAliveTime:(double)arg3 {
    %orig(keepAliveDuration,arg2,0.0);
}

// 支持所有设备
+ (bool)reachabilitySupported {
    return YES;
}

// 启用Reachability
- (bool)reachabilityEnabled {
    return YES;
}

// 设置启用Reachability
- (void)setReachabilityEnabled:(bool)arg1 {
    %orig(YES);
}

// 边缘滑动手势停用Reachability
- (void)_panToDeactivateReachability:(id)arg1 {
    return;
}

// 手势识别器是否应该开始
- (_Bool)gestureRecognizerShouldBegin:(id)arg1 {
    if ((![arg1 isKindOfClass:%c(SBScreenEdgePanGestureRecognizer)] && ![arg1 isKindOfClass:%c(SBReachabilityGestureRecognizer)])) return false;
    //if ([arg1 isKindOfClass:%c(UITapGestureRecognizer)]) return false;//阻止点击手势

    return %orig;
}
- (BOOL)canActivateReachability {
    if (isFromCustomGesture) {
        return YES; // 允许自定义手势激活
    }
    return NO; // 阻止其他方式激活
}
// 移除点击停用手势
/*
- (void)_tapToDeactivateReachability:(id)arg1 {
    return;
}
*/
%end

// 确保搜索控制器支持Reachability
%hook SBSearchViewController
- (bool)reachabilitySupported {
    return YES;
}
%end

// 确保应用切换器支持Reachability
%hook SBAppSwitcherController
- (bool)_shouldRespondToReachability {
    return YES;
}
%end

// 确保图标控制器支持Reachability
%hook SBIconController
- (bool)_shouldRespondToReachability {
    return YES;
}
%end

// 确保应用支持Reachability
%hook SBApplication
- (bool)isReachabilitySupported {
    return YES;
}

- (void)setReachabilitySupported:(bool)arg1 {
    %orig(YES);
}
%end

// 确保SpringBoard支持Reachability
%hook SpringBoard
- (void)_setReachabilitySupported:(bool)arg1 {
    %orig(YES);
}
%end

// Reachability窗口触摸处理
%hook SBReachabilityWindow
// 触摸传递处理
- (id)hitTest:(CGPoint)arg1 withEvent:(id)arg2 {
    UIView *candidate = %orig;
    // 获取 SBReachabilityBackgroundView 的 _topWallpaperEffectView 属性
    SBWallpaperEffectView *correctView = MSHookIvar<SBWallpaperEffectView *>(((SBReachabilityBackgroundView *)self.rootViewController.view), "_topWallpaperEffectView");
    if (arg1.y <= 0) {
        candidate = [correctView hitTest:[correctView convertPoint:arg1 fromView:self] withEvent:arg2];
        if (emptyView) {
            candidate = emptyView;
            emptyView = nil;
        } else {
            emptyView = candidate;
        }
    }
    return candidate;// 返回最终的候选视图
}
%end

// Reachability背景视图hook
%hook SBReachabilityBackgroundView
// 设置chevron图标透明度
- (void)setChevronAlpha:(double)arg1 {
    if (enable) {
        arg1 = 0;  // 使用自定义透明度
    }
    %orig;
}
%end

// Reachability背景视图控制器hook
%hook SBReachabilityBackgroundViewController
%property (nonatomic, retain) NSTimer *updateTimer;

// 视图即将显示时调用
-(void)viewWillAppear:(BOOL)arg1 {
    %orig;
    [[%c(SBReachabilityManager) sharedInstance] _notifyObserversReachabilityYOffsetDidChange];
    [self addReachPlayerContainerView];  // 添加自定义视图
    //[[%c(SBMediaController) sharedInstance] setNowPlayingInfo:0];
}

// 添加自定义容器视图
%new
- (void)addReachPlayerContainerView {
    SBWallpaperEffectView *topWallpaperEffectView = MSHookIvar<SBWallpaperEffectView *>(((SBReachabilityBackgroundView *)self.view), "_topWallpaperEffectView");
    if ([topWallpaperEffectView.subviews containsObject:containerView]) {
                return; // 已经添加过，直接返回
            }
    if (topWallpaperEffectView != nil) {
        containerView = [ReachPlayerContainerView new];
        containerView.frame = topWallpaperEffectView.bounds;

        [topWallpaperEffectView addSubview:containerView];
        
        // 设置自动布局约束
        containerView.translatesAutoresizingMaskIntoConstraints = false;
        [containerView.bottomAnchor constraintEqualToAnchor:topWallpaperEffectView.bottomAnchor constant:0].active = YES;
        [containerView.leftAnchor constraintEqualToAnchor:topWallpaperEffectView.leftAnchor constant:0].active = YES;
        [containerView.rightAnchor constraintEqualToAnchor:topWallpaperEffectView.rightAnchor constant:0].active = YES;
        [containerView.topAnchor constraintEqualToAnchor:topWallpaperEffectView.topAnchor constant:0].active = YES;
    }
}
- (void)viewDidDisappear:(BOOL)arg1 {
    %orig;
    if (containerView) {
        [containerView removeFromSuperview];
        containerView = nil;
    }
}
%end

// SpringBoard启动完成hook
%hook SpringBoard
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    %orig;
    loadPreferences();  // 加载偏好设置
}
%end
%end

// 构造函数
%ctor {
    BOOL shouldLoad = NO;
    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger count = args.count;
    if (count != 0) {
        NSString *executablePath = args[0];
        if (executablePath) {
            // 检查进程名称决定是否加载tweak
            NSString *processName = [executablePath lastPathComponent];
            BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];
            BOOL isPreferences = [processName isEqualToString:@"Preferences"];
            BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;
            BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;
            BOOL skip = [processName isEqualToString:@"AdSheet"]
            || [processName isEqualToString:@"CoreAuthUI"]
            || [processName isEqualToString:@"InCallService"]
            || [processName isEqualToString:@"MessagesNotificationViewService"]
            || [executablePath rangeOfString:@".appex/"].location != NSNotFound;
            
            if (!isFileProvider && (isSpringBoard || isApplication || isPreferences) && !skip) {
                shouldLoad = YES;
            }
        }
    }
    
    if (shouldLoad) {
        loadPreferences(); // 加载偏好设置
        // 添加偏好设置变更观察者
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPreferences, (CFStringRef)preferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    
        if (enable) {
            %init(ReachPlayer);  // 初始化tweak
            return;
        }
        return;
    }
}