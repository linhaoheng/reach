#import "LHHNowPlayingProgressView.h"
#import <MediaRemote/MediaRemote.h>

@implementation LHHNowPlayingProgressView

- (instancetype)init {
    self = [super init];
    if (self) {
        // 启用用户交互
        self.userInteractionEnabled = YES;
        
        // 初始化剩余轨道视图（未播放部分）
        self.remainingTrack = [[UIView alloc] init];
        self.remainingTrack.layer.cornerRadius = 2; // 圆角半径
        self.remainingTrack.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1]; // 浅灰色背景
        self.remainingTrack.translatesAutoresizingMaskIntoConstraints = NO; // 启用自动布局
        [self addSubview:self.remainingTrack]; // 添加到当前视图
        
        // 初始化已播放轨道视图
        self.elapsedTrack = [[UIView alloc] init];
        self.elapsedTrack.layer.cornerRadius = 2; // 圆角半径
        self.elapsedTrack.backgroundColor = [UIColor blackColor]; // 黑色背景
        self.elapsedTrack.translatesAutoresizingMaskIntoConstraints = NO; // 启用自动布局
        [self addSubview:self.elapsedTrack]; // 添加到当前视图
        
        // 初始化进度条旋钮视图
        self.knobView = [[LHHNowPlayingProgressKnobView alloc] init];
        self.knobView.translatesAutoresizingMaskIntoConstraints = NO; // 启用自动布局
        [self addSubview:self.knobView]; // 添加到当前视图
        
        // 初始化已播放时间标签
        self.elapsedLabel = [[UILabel alloc] init];
        self.elapsedLabel.textColor = [UIColor blackColor]; // 黑色文字
        self.elapsedLabel.font = [UIFont boldSystemFontOfSize:13]; // 加粗字体，13号大小
        self.elapsedLabel.text = @"0:00"; // 初始文本
        self.elapsedLabel.translatesAutoresizingMaskIntoConstraints = NO; // 启用自动布局
        [self addSubview:self.elapsedLabel]; // 添加到当前视图
        
        // 初始化剩余时间标签
        self.remainingLabel = [[UILabel alloc] init];
        self.remainingLabel.textColor = [UIColor lightGrayColor]; // 浅灰色文字
        self.remainingLabel.font = [UIFont boldSystemFontOfSize:13]; // 加粗字体，13号大小
        self.remainingLabel.textAlignment = NSTextAlignmentRight; // 右对齐
        self.remainingLabel.text = @"0:00"; // 初始文本
        self.remainingLabel.translatesAutoresizingMaskIntoConstraints = NO; // 启用自动布局
        [self addSubview:self.remainingLabel]; // 添加到当前视图
        
        // 添加旋钮的拖动手势识别器
        UIPanGestureRecognizer *scrubRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scrubbed:)];
        scrubRecognizer.minimumNumberOfTouches = 1; // 最少需要1个触摸点
        scrubRecognizer.maximumNumberOfTouches = 1; // 最多允许1个触摸点
        [self.knobView addGestureRecognizer:scrubRecognizer]; // 将手势识别器添加到旋钮视图
        
        // 添加全区域滑动手势识别器（用于直接拖动进度条）
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture]; // 将手势识别器添加到当前视图
        
        // 激活所有约束
        [self activateConstraints];
        
        // 初始化时长和已播放时间
        self.duration = 0;
        self.elapsedTime = 0;
    }
    return self;
}

- (void)activateConstraints {
    // 创建已播放轨道宽度的约束（初始为3pt）
    self.elapsedTrackWidthConstraint = [self.elapsedTrack.widthAnchor constraintEqualToConstant:3];
    
    // 创建旋钮视图中心X约束（初始对齐剩余轨道的左侧）
    self.knobViewCenterXConstraint = [self.knobView.centerXAnchor constraintEqualToAnchor:self.remainingTrack.leadingAnchor];

    // 激活所有约束
    [NSLayoutConstraint activateConstraints:@[
        // 剩余轨道的布局约束
        [self.remainingTrack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:6], // 距离父视图左侧6pt
        [self.remainingTrack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-6], // 距离父视图右侧6pt
        [self.remainingTrack.topAnchor constraintEqualToAnchor:self.topAnchor constant:8], // 距离父视图顶部8pt
        [self.remainingTrack.heightAnchor constraintEqualToConstant:3], // 高度固定为3pt
        
        // 已播放轨道的布局约束
        [self.elapsedTrack.leadingAnchor constraintEqualToAnchor:self.remainingTrack.leadingAnchor], // 与剩余轨道左侧对齐
        [self.elapsedTrack.topAnchor constraintEqualToAnchor:self.remainingTrack.topAnchor], // 与剩余轨道顶部对齐
        self.elapsedTrackWidthConstraint, // 使用之前创建的宽度约束
        [self.elapsedTrack.heightAnchor constraintEqualToConstant:3], // 高度固定为3pt
        
        // 旋钮视图的布局约束
        self.knobViewCenterXConstraint, // 使用中心X约束
        [self.knobView.centerYAnchor constraintEqualToAnchor:self.elapsedTrack.centerYAnchor], // 垂直居中对齐已播放轨道
        [self.knobView.widthAnchor constraintEqualToConstant:19], // 宽度固定为19pt
        [self.knobView.heightAnchor constraintEqualToConstant:19], // 高度固定为19pt
        
        // 已播放时间标签的布局约束
        [self.elapsedLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:6], // 距离父视图左侧6pt
        [self.elapsedLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:19], // 距离父视图顶部19pt
        [self.elapsedLabel.widthAnchor constraintEqualToConstant:100], // 宽度固定为50pt
        //[self.elapsedLabel.heightAnchor constraintEqualToConstant:12], // 高度固定为12pt
        
        // 剩余时间标签的布局约束
        [self.remainingLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-6], // 距离父视图右侧6pt
        [self.remainingLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:19], // 距离父视图顶部19pt
        [self.remainingLabel.widthAnchor constraintEqualToConstant:100], // 宽度固定为50pt
        //[self.remainingLabel.heightAnchor constraintEqualToConstant:12], // 高度固定为12pt
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 在布局更新后，获取剩余轨道的宽度并存储到trackWidth属性中
    self.trackWidth = self.remainingTrack.frame.size.width;
}

- (void)startTimer {
    // 停止现有的计时器（如果存在）
    [self stopTimer];
    // 创建一个新的计时器，每秒触发一次tickTimeElapsed方法
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(tickTimeElapsed) userInfo:nil repeats:YES];
}

- (void)stopTimer {
    // 如果计时器存在，则停止并置为nil
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)tickTimeElapsed {
    // 通过MediaRemote框架获取当前播放信息
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
        if (!result) return; // 如果没有获取到结果，直接返回
        
        NSDictionary *dict = (__bridge NSDictionary *)result; // 将CFDictionary转换为NSDictionary
        NSNumber *playbackRate = dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoPlaybackRate]; // 获取播放速率
        if (!playbackRate || playbackRate.doubleValue == 0.0) return; // 如果播放速率为0或未获取到，直接返回
        
        // 计算实际已播放时间
        CFAbsoluteTime timeStarted = CFDateGetAbsoluteTime((CFDateRef)dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTimestamp]);
        double lastStoredTime = [dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime] doubleValue];
        double realTimeElapsed = (CFAbsoluteTimeGetCurrent() - timeStarted) + (lastStoredTime > 1 ? lastStoredTime : 0);
        
        // 更新已播放时间
        self.elapsedTime = realTimeElapsed;
    });
}

- (void)setDuration:(double)duration {
    _duration = duration; // 设置时长属性
    
    // 如果时长无效（<=0），则设置为0
    if (!duration || duration < 0) duration = 0;
    
    // 计算分钟和秒数
    NSUInteger m = ((NSUInteger)floor(duration) / 60);
    NSUInteger s = (NSUInteger)floor(duration) % 60;
    
    // 更新剩余时间标签的文本
    self.remainingLabel.text = [NSString stringWithFormat:@"%lu:%02lu", m, s];
}

- (void)setElapsedTime:(double)elapsed {
    // 如果已播放时间超过总时长，则设置为总时长
    if (elapsed > self.duration) {
        elapsed = self.duration;
    }
    _elapsedTime = elapsed; // 设置已播放时间属性
    
    // 如果已播放时间无效（<=0），则设置为0
    if (!elapsed || elapsed < 0) elapsed = 0;
    
    // 计算分钟和秒数
    NSUInteger m = ((NSUInteger)floor(elapsed) / 60);
    NSUInteger s = (NSUInteger)floor(elapsed) % 60;
    
    // 计算已播放轨道的宽度（基于总宽度和播放进度）
    CGFloat progressWidth = self.trackWidth * (self.duration > 0 ? (elapsed / self.duration) : 0);
    
    // 更新已播放轨道的宽度约束
    self.elapsedTrackWidthConstraint.constant = progressWidth;
    
    // 更新旋钮视图的中心X约束（基于剩余轨道的左侧位置加上进度宽度）
    self.knobViewCenterXConstraint.constant = progressWidth;
    
    // 更新已播放时间标签的文本
    self.elapsedLabel.text = [NSString stringWithFormat:@"%lu:%02lu", m, s];
}

- (void)scrubbed:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self stopTimer];
        [UIView animateWithDuration:0.2 animations:^{
            self.knobView.transform = CGAffineTransformMakeScale(1.5, 1.5);
        }];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat distance = self.knobViewCenterXConstraint.constant + [sender translationInView:self].x;
        if (distance < 0) distance = 0;
        
        // 当滑到最后时，稍微往回一点
        CGFloat endThreshold = self.trackWidth - 0.1;
        if (distance >= endThreshold) {
            distance = endThreshold; // 回退到距离终点5pt的位置
        } else if (distance > self.trackWidth) {
            distance = self.trackWidth;
        }
        
        if (self.duration > 0) {
            self.elapsedTime = (distance / self.trackWidth) * self.duration;
        } else {
            self.elapsedTrackWidthConstraint.constant = distance;
            self.knobViewCenterXConstraint.constant = distance;
        }
        
        [sender setTranslation:CGPointZero inView:self];
    } else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        [UIView animateWithDuration:0.2 animations:^{
            self.knobView.transform = CGAffineTransformIdentity;
        }];
        
        if (self.duration > 0) {
            double distance = self.knobViewCenterXConstraint.constant;
            double elapsedTime = distance / self.trackWidth * self.duration;
            MRMediaRemoteSetElapsedTime(elapsedTime);
            [self startTimer];
        }
    }
}

- (void)updateNowPlayingImmediately {
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
        if (!result) return;
        
        NSDictionary *dict = (__bridge NSDictionary *)result;
        
        double duration = [dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDuration] doubleValue];
        double elapsed = [dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime] doubleValue];
        
        if (duration > 0) {
            self.duration = duration;
        }
        
        // 有时 elapsed 是缓存的旧值，加入 timestamp 修正
        CFAbsoluteTime timeStarted = CFDateGetAbsoluteTime((CFDateRef)dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTimestamp]);
        NSNumber *playbackRate = dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoPlaybackRate];
        
        double realTimeElapsed = elapsed;
        if (playbackRate && playbackRate.doubleValue > 0.0) {
            realTimeElapsed += (CFAbsoluteTimeGetCurrent() - timeStarted);
        }
        
        self.elapsedTime = realTimeElapsed;
    });
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // 空实现，用于防止手势被传递给父视图（可选）
}

// 判断当前是否正在跟踪（拖动）进度条
- (BOOL)isTracking {
    // 获取旋钮手势识别器的状态
    UIGestureRecognizerState knobState = self.knobView.gestureRecognizers.firstObject.state;
    
    // 获取全区域手势识别器的状态
    UIGestureRecognizerState progressState = [self.gestureRecognizers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIGestureRecognizer *gesture, NSDictionary *bindings) {
        return [gesture isKindOfClass:[UIPanGestureRecognizer class]];
    }]].firstObject.state;
    
    // 返回是否任一手势处于拖动状态
    return (knobState == UIGestureRecognizerStateChanged) || (progressState == UIGestureRecognizerStateChanged);
}

// 处理全区域滑动手势（用于直接拖动进度条）
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self stopTimer];
        [UIView animateWithDuration:0.2 animations:^{
            self.knobView.transform = CGAffineTransformMakeScale(1.5, 1.5);
        }];
    }
    
    CGFloat progressWidth = self.remainingTrack.frame.size.width;
    CGFloat newKnobCenterX = MAX(0, MIN(self.knobViewCenterXConstraint.constant + translation.x, progressWidth));
    
    [gesture setTranslation:CGPointZero inView:self];
    
    // 当滑到最后时，稍微往回一点
    CGFloat endThreshold = progressWidth - 0.1; // 距离终点5pt时认为是"最后"
    if (newKnobCenterX >= endThreshold) {
        newKnobCenterX = endThreshold; // 回退到距离终点5pt的位置
    }
    
    self.elapsedTime = (newKnobCenterX / progressWidth) * self.duration;
    self.elapsedTrackWidthConstraint.constant = newKnobCenterX;
    self.knobViewCenterXConstraint.constant = newKnobCenterX;
    
    [self layoutIfNeeded];
    
    if (gesture.state == UIGestureRecognizerStateEnded ||
        gesture.state == UIGestureRecognizerStateCancelled) {
        
        [UIView animateWithDuration:0.2 animations:^{
            self.knobView.transform = CGAffineTransformIdentity;
        }];
        
        if (self.duration > 0) {
            MRMediaRemoteSetElapsedTime(self.elapsedTime);
        }
        
        MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
            if (result) {
                NSDictionary *dict = (__bridge NSDictionary *)result;
                NSNumber *rate = [dict objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoPlaybackRate];
                if ([rate boolValue]) {
                    [self startTimer];
                }
            }
        });
    }
}
@end
