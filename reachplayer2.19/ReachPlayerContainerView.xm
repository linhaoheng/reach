#import "ReachPlayerContainerView.h"

@implementation ReachPlayerContainerView

#pragma mark - 初始化方法
- (instancetype)init {
    self = [super init];
    if (self) {
        // 添加各个UI组件
        [self loadCustomFont]; // 加载自定义字体
        [self addBackgroundImage];          // 添加背景图片
        [self addArtworkContainerView];     // 添加专辑封面容器
        [self addLabelsStackView];          // 添加标签堆栈视图（歌曲名、艺术家、专辑）
        [self addControlsStackView];        // 添加控制按钮堆栈视图（上一首、播放/暂停、下一首）
        [self updateImage];                 // 更新图片信息
        [self updateTransition];            // 更新过渡动画
        [self addProgressView];  // 添加进度条方法声明
        [self addmshfView];
        [self addSnowfallEmitterView];
        // 根据当前是否有播放内容决定是否隐藏视图
        if (self.nowPlayingInfoSong.text == nil) {
            if (self.mshfView) {
                [self.mshfView stop];
            }
            [self setHidden:YES];
        } else {
            [self setHidden:NO];
        }
        
        // 设置通知中心监听
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(updateImage) name:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDidChangeNotification object:nil];
        [notificationCenter postNotificationName:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDidChangeNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playingDidChange:) name:(__bridge NSString *)kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:(__bridge NSString *)kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification object:nil];
        
    }
    return self;
}

#pragma mark - 音频可视化
- (void)addmshfView {
    if (!self.mshfView && enablemshf) {
        self.mshfView = [[MSHFJelloView alloc] initWithFrame:CGRectZero];
        //self.mshfView.backgroundColor = [UIColor redColor];
        self.mshfView.numberOfPoints = numberOfPoints;
        self.mshfView.waveOffset = WaveOffset;
        self.mshfView.sensitivity = Sensitivity;
        self.mshfView.gain = Gain;
        self.mshfView.limiter = Limiter;
        self.mshfView.disableBatterySaver = DisableBatterySaver;
        self.mshfView.audioProcessing.fft = EnableFFT;
        self.mshfView.padCount = 3;
        Fps = MAX(10.0, MIN(80.0, Fps));
        if (@available(iOS 15.0, *)) {
            self.mshfView.displayLink.preferredFrameRateRange = CAFrameRateRangeMake(Fps / 2.0, Fps, Fps);
        } else {
            self.mshfView.displayLink.preferredFramesPerSecond = (int)Fps;
        }

        [self.mshfView updateWaveColor:[UIColor colorWithHexString:WaveColor].CGColor
                subwaveColor:[[UIColor colorWithHexString:WaveColor] colorWithAlphaComponent:0.7].CGColor];
    
    
    [self addSubview:self.mshfView];
    self.mshfView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mshfView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:waveOffsetX].active = YES;
    [self.mshfView.widthAnchor constraintEqualToConstant:widthmshf].active = YES; // 自定义宽度，比如 200
    //[self.mshfView.heightAnchor constraintEqualToConstant:60].active = YES; // 自定义高度，比如 60
    [self.mshfView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES; // 距底部 30 的间距

    }
}

#pragma mark - 粒子效果
- (void)addSnowfallEmitterView {
    if (!snowEnabled) {
        [_snowEmitterLayer removeFromSuperlayer]; // 移除现有的雪花图层
        _snowEmitterLayer = nil; // 释放内存
        return; // 直接返回
    }

    if (_snowEmitterLayer) return; // 如果雪花图层已存在，直接返回

    // 本地定义雪花文件名和数量，不用属性
    NSString *flakeFileName = @"Snoverlay.png"; // 雪花图片名称（也可以是 @"XMASSnowflake.png"）
    NSInteger flakesCount = numSnowflakes;      // 雪花数量（由外部变量决定）
    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;

    // 拼接雪花图片的完整路径
    NSString *flakePath = [presetThemesPath stringByAppendingPathComponent:flakeFileName];
    UIImage *flakeImg = [UIImage imageWithContentsOfFile:flakePath];
    if (!flakeImg) return; // 如果图片加载失败，直接返回

    CAEmitterCell *flakeCell = [CAEmitterCell emitterCell];
    flakeCell.name = @"flakeCell";
    flakeCell.contents = (__bridge id)flakeImg.CGImage; // 设置雪花图片

    // 控制雪花大小
    flakeCell.scale = selfFlake;          // 基础大小
    flakeCell.scaleRange = 0.1;           // 大小随机范围（±0.4）

    // 控制雪花生成和运动
    flakeCell.birthRate = flakesCount >> 3; // 每秒生成的雪花数量（总数 / 8）
    flakeCell.lifetime = snowlifetime;            // 雪花存活时间（秒）
    flakeCell.velocity = snowvelocity;              // 下落速度
    flakeCell.velocityRange = 35;        // 速度随机范围（±100）
    flakeCell.yAcceleration = 0;         // Y 轴加速度（影响下落速度）
    flakeCell.xAcceleration = 0;          // X 轴加速度（影响横向飘动）
    flakeCell.zAcceleration = 5;          // Z 轴加速度（3D 效果，可选）
    flakeCell.spinRange = M_PI * 2;       // 旋转角度随机范围（0~2π，即 0°~360°）
    flakeCell.emissionRange = 0;//M_PI;       // 发射角度范围（-π~π，即 -180°~180°，影响飘落方向）
    flakeCell.emissionLongitude = M_PI;        // 发射方向向下
    //flakeCell.alphaSpeed = -0.02;  // 逐渐消失

    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.seed = arc4random(); // 每次启动都不一样
    emitter.emitterPosition = CGPointMake(screenWidth/2, snowheight); // 发射器位置（屏幕顶部居中）
    emitter.emitterSize = CGSizeMake(screenWidth * 1.2, 0);       // 发射范围（宽度略大于屏幕）
    emitter.emitterShape = kCAEmitterLayerLine; // 发射器形状（线性，适合雪花从顶部飘落）
    //emitter.emitterMode = kCAEmitterLayerSurface;

    emitter.beginTime = CACurrentMediaTime();   // 开始时间（立即生效）
    //emitter.timeOffset = 5 + arc4random_uniform(5000) / 5000.0;       // 时间偏移（可调整雪花初始状态）
    emitter.emitterCells = @[flakeCell];        // 绑定雪花粒子

    [self.layer insertSublayer:emitter above:self.backgroundImageView.layer]; // 添加到背景图上方
    _snowEmitterLayer = emitter; // 保存引用，方便后续管理
}



#pragma mark - 添加背景图片视图
- (void)addBackgroundImage {
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;  // 设置图片填充模式
    [self addSubview:self.backgroundImageView];  // 添加到视图
    self.backgroundImageView.userInteractionEnabled = YES; // ⚠️ 很关键！！
    UILongPressGestureRecognizer *tapLikeGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(closeReachability:)];
    tapLikeGesture.minimumPressDuration = 0; // 立即触发
    tapLikeGesture.allowableMovement = 10; // 容忍少量移动
    tapLikeGesture.cancelsTouchesInView = NO;
    [self.backgroundImageView addGestureRecognizer:tapLikeGesture];
    // 设置自动布局约束
    self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = false;
    [self.backgroundImageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:reachOffsetRP + 200].active = YES;
    [self.backgroundImageView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:0].active = YES;
    [self.backgroundImageView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:0].active = YES;
    //[self.backgroundImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:reachOffsetRP].active = YES;

}
#pragma mark - 关闭便捷访问
- (void)closeReachability:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // 手指按下时触发
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        // 手指抬起时触发
        [[%c(SBReachabilityManager) sharedInstance] deactivateReachability];
    }
}
#pragma mark - 添加专辑封面容器视图
- (void)addArtworkContainerView {
    self.artworkContainerView = [[ReachPlayerArtworkContainerView alloc] initWithFrame:CGRectMake(0,0,artworkSizeRP,artworkSizeRP)];
    self.artworkContainerView.contentMode = UIViewContentModeScaleAspectFill;  // 设置内容填充模式
    self.artworkContainerView.layer.masksToBounds = YES;  // 裁剪超出边界的内容
    self.artworkContainerView.layer.cornerCurve = kCACornerCurveContinuous;  // 平滑圆角
    
    if (albumCircleView) {
        self.artworkContainerView.layer.cornerRadius = artworkSizeRP / 2.0; // 圆形专辑
    } else {
        self.artworkContainerView.layer.cornerRadius = self.artworkContainerView.frame.size.height/16;  // 设置圆角半径
    }
    [self addSubview:self.artworkContainerView];  // 添加到视图
    
    // 设置自动布局约束
    self.artworkContainerView.translatesAutoresizingMaskIntoConstraints = false;
    [self.artworkContainerView.widthAnchor constraintEqualToConstant:artworkSizeRP].active = true;
    [self.artworkContainerView.heightAnchor constraintEqualToConstant:artworkSizeRP].active = true;
    [self.artworkContainerView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:albumArtworkViewX+positionXRP-(artworkSizeRP/2)-15].active = true;
    [self.artworkContainerView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:albumArtworkViewY+positionYRP+(artworkSizeRP/2)].active = true;
    
    // 创建专辑封面视图
    self.artworkContainerView.artworkView = [[UIImageView alloc] initWithFrame:CGRectMake(0,self.center.y,artworkSizeRP,artworkSizeRP)];
    self.artworkContainerView.artworkView.contentMode = UIViewContentModeScaleAspectFill;
    self.artworkContainerView.artworkView.layer.masksToBounds = YES;
    self.artworkContainerView.artworkView.layer.cornerCurve = kCACornerCurveContinuous;
    self.artworkContainerView.artworkView.layer.cornerRadius = albumCircleView ? (artworkSizeRP / 2.0) : (artworkSizeRP/16);
    self.artworkContainerView.artworkView.layer.minificationFilter = kCAFilterTrilinear;
    self.artworkContainerView.artworkView.layer.magnificationFilter = kCAFilterTrilinear;
    [self.artworkContainerView insertSubview:self.artworkContainerView.artworkView atIndex:1];  // 添加到容器中
    
    // 设置专辑封面视图的约束
    self.artworkContainerView.artworkView.translatesAutoresizingMaskIntoConstraints = false;
    [self.artworkContainerView.artworkView.widthAnchor constraintEqualToConstant:artworkSizeRP].active = true;
    [self.artworkContainerView.artworkView.heightAnchor constraintEqualToConstant:artworkSizeRP].active = true;
    [self.artworkContainerView.artworkView.centerXAnchor constraintEqualToAnchor:self.artworkContainerView.centerXAnchor constant:0].active = true;
    [self.artworkContainerView.artworkView.centerYAnchor constraintEqualToAnchor:self.artworkContainerView.centerYAnchor constant:0].active = true;
    self.artworkContainerView.userInteractionEnabled = YES; // ⚠️ 很关键！！
    // 替换原有点击手势为拖动手势（兼容点击）
    UILongPressGestureRecognizer *tapLikeGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleArtworkTap:)];
    tapLikeGesture.minimumPressDuration = 0; // 立即触发
    tapLikeGesture.allowableMovement = 10; // 容忍少量移动
    tapLikeGesture.cancelsTouchesInView = NO;
    [self.artworkContainerView addGestureRecognizer:tapLikeGesture];



    // 创建叠加图层（比专辑封面大一圈，居中）
    UIImage *overlayImage = [UIImage imageNamed:@"record"
                                   inBundle:[NSBundle bundleWithPath:presetThemesPath]
              compatibleWithTraitCollection:nil];
    UIImage *tonearmImage = [UIImage imageNamed:@"cz"
                                   inBundle:[NSBundle bundleWithPath:presetThemesPath]
              compatibleWithTraitCollection:nil];
              
    if (overlayImage && showOverlay && albumCircleView) {
        UIImageView *overlayView = [[UIImageView alloc] initWithImage:overlayImage];
        overlayView.contentMode = UIViewContentModeScaleAspectFit;
        //overlayView.alpha = 0.5; // 半透明
        overlayView.translatesAutoresizingMaskIntoConstraints = NO;
        overlayView.userInteractionEnabled = NO; // 避免影响点击

        [self insertSubview:overlayView aboveSubview:self.artworkContainerView];

        // 约束：中心对齐 artworkContainerView，但尺寸更大
        [NSLayoutConstraint activateConstraints:@[
            [overlayView.centerXAnchor constraintEqualToAnchor:self.artworkContainerView.centerXAnchor],
            [overlayView.centerYAnchor constraintEqualToAnchor:self.artworkContainerView.centerYAnchor],
            [overlayView.widthAnchor constraintEqualToAnchor:self.artworkContainerView.widthAnchor multiplier:1.3],
            [overlayView.heightAnchor constraintEqualToAnchor:overlayView.widthAnchor]
        ]];

        if (tonearmImage) {
            self.tonearmlayView = [[UIImageView alloc] initWithImage:tonearmImage];
            self.tonearmlayView.contentMode = UIViewContentModeScaleAspectFit;
            //tonearmlayView.alpha = 0.5; // 半透明
            self.tonearmlayView.translatesAutoresizingMaskIntoConstraints = NO;
            self.tonearmlayView.userInteractionEnabled = NO; // 避免影响点击

            [self insertSubview:self.tonearmlayView aboveSubview:overlayView];

            [NSLayoutConstraint activateConstraints:@[
                [self.tonearmlayView.widthAnchor constraintEqualToConstant:artworkSizeRP*1.5],
                [self.tonearmlayView.heightAnchor constraintEqualToConstant:artworkSizeRP*1.5],
                [self.tonearmlayView.centerXAnchor constraintEqualToAnchor:self.artworkContainerView.centerXAnchor constant:artworkSizeRP / 2.0 + tonearmViewX],
                [self.tonearmlayView.bottomAnchor constraintEqualToAnchor:self.artworkContainerView.topAnchor constant:artworkSizeRP / 2.0 + tonearmViewY]
            ]];
            // 设置旋转支点
            self.tonearmlayView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        }
    }
}
#pragma mark - 打开播放应用
- (void)handleArtworkTap:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // 手指按下时触发
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        // 手指抬起时触发
        dispatch_async(dispatch_get_main_queue(), ^{
            MRMediaRemoteGetNowPlayingClient(dispatch_get_main_queue(), ^(id client) {
                if (client != nil) {
                    NSString *bundleIdentifier = MRNowPlayingClientGetBundleIdentifier(client);
                    if (bundleIdentifier == nil) {
                        bundleIdentifier = MRNowPlayingClientGetParentAppBundleIdentifier(client);
                    }
                    [[UIApplication sharedApplication] launchApplicationWithIdentifier:bundleIdentifier suspended:NO];
                }
            });
        });
    }
}

// 手势处理方法
- (void)handleAlbumGesture:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [gesture velocityInView:gesture.view];
        if (velocity.x > 100) { // 右滑
            MRMediaRemoteSendCommand(kMRNextTrack, nil);
        } else if (velocity.x < -100) { // 左滑
            MRMediaRemoteSendCommand(kMRPreviousTrack, nil);
        } else { // 视为点击
            MRMediaRemoteSendCommand(kMRTogglePlayPause, nil);
        }
        
        if (Vibration) {
            UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] 
                initWithStyle:UIImpactFeedbackStyleLight];
            [gen impactOccurred];
        }
    }
}
#pragma mark - 播放动画 - 唱针落下
- (void)playAnimation {
    self.tonearmlayView.alpha = 0; // 初始透明
    [UIView animateWithDuration:1 
                          delay:0 
         usingSpringWithDamping:1
          initialSpringVelocity:0 
                        options:UIViewAnimationOptionCurveEaseInOut 
                     animations:^{
        // 旋转-30度（可根据需要调整角度）
        self.tonearmlayView.alpha = 1.0; // 淡入
        self.tonearmlayView.transform = CGAffineTransformMakeRotation(M_PI/4);
    } completion:nil];
}

// 暂停动画 - 唱针抬起
- (void)pauseAnimation {
    [UIView animateWithDuration:0.8
                     animations:^{
        // 恢复原始位置
        self.tonearmlayView.alpha = 0;
        self.tonearmlayView.transform = CGAffineTransformIdentity;
    }];
}


#pragma mark - 开始旋转容器视图
- (void)startRotatingContainer {
    // 如果正在减速，打断减速动画并恢复状态
    if (self.isStopping) {
        CGFloat currentAngle = [[self.artworkContainerView.layer.presentationLayer valueForKeyPath:@"transform.rotation.z"] floatValue];
        self.artworkContainerView.layer.transform = CATransform3DMakeRotation(currentAngle, 0, 0, 1);
        self.currentRotationAngle = currentAngle;
        [self.artworkContainerView.layer removeAnimationForKey:@"slowStop"];
        self.isStopping = NO;
        self.isAnimating = NO;
    }

    // 如果已经在旋转中，跳过
    if (self.isAnimating) return;

    // 创建旋转动画
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.fromValue = @(self.currentRotationAngle);
    rotation.toValue = @(self.currentRotationAngle + 2 * M_PI);
    rotation.duration = 60.0 / baseRotationSpeed;
    rotation.repeatCount = HUGE_VALF;
    rotation.removedOnCompletion = NO;
    rotation.fillMode = kCAFillModeForwards;
    rotation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    [self.artworkContainerView.layer addAnimation:rotation forKey:@"rotation"];
    self.isAnimating = YES;
}

#pragma mark - 暂停旋转容器视图（带减速效果）
- (void)pauseRotatingContainer {
    if (!self.isAnimating || self.isStopping) return;

    self.isStopping = YES;

    CGFloat currentAngle = [[self.artworkContainerView.layer.presentationLayer valueForKeyPath:@"transform.rotation.z"] floatValue];
    self.currentRotationAngle = currentAngle;

    [self.artworkContainerView.layer removeAnimationForKey:@"rotation"];
    self.artworkContainerView.layer.transform = CATransform3DMakeRotation(currentAngle, 0, 0, 1);

    CABasicAnimation *slowDown = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    slowDown.fromValue = @(currentAngle);
    slowDown.toValue = @(currentAngle + M_PI / 10.0);
    slowDown.duration = 0.8;
    slowDown.removedOnCompletion = NO;
    slowDown.fillMode = kCAFillModeForwards;
    slowDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    [self.artworkContainerView.layer addAnimation:slowDown forKey:@"slowStop"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 如果播放已经中断减速，则不执行后续修正
        if (self.isStopping) {
            CGFloat finalAngle = currentAngle + M_PI / 10.0;
            self.currentRotationAngle = finalAngle;
            [self.artworkContainerView.layer removeAllAnimations];
            self.artworkContainerView.layer.transform = CATransform3DMakeRotation(finalAngle, 0, 0, 1);
            self.isStopping = NO;
            self.isAnimating = NO;
        }
    });
}

#pragma mark - 加载自定义字体
- (void)loadCustomFont {
    NSString *fontFileName = @"lhhFont"; // 不带扩展名
    NSBundle *customBundle = [NSBundle bundleWithPath:presetThemesPath];
    NSString *fontPath = [customBundle pathForResource:fontFileName ofType:@"ttf"];

    if (!fontPath) {
        fontPath = [customBundle pathForResource:fontFileName ofType:@"otf"];
    }
    // 1. 检查字体文件是否存在
    if (!fontPath) {
        NSLog(@"❌ 字体文件未找到: %@", fontFileName);
        return;
    }
    
    // 2. 创建字体URL
    NSURL *fontURL = [NSURL fileURLWithPath:fontPath];
    
    // 3. 尝试获取字体名称（同时检查是否已注册）
    CGDataProviderRef provider = CGDataProviderCreateWithURL((__bridge CFURLRef)fontURL);
    CGFontRef font = CGFontCreateWithDataProvider(provider);
    
    // 3.1 获取字体名称（使用 CFBridgingRelease 转移所有权）
    NSString *fontName = CFBridgingRelease(CGFontCopyPostScriptName(font));
    
    // 3.2 释放资源（必须释放，避免内存泄漏）
    if (provider) CFRelease(provider);
    if (font) CFRelease(font);
    
    // 4. 检查字体是否已注册
    if ([UIFont fontWithName:fontName size:12]) {
        NSLog(@"字体已注册，直接使用: %@", fontName);
        self.customFontName = fontName;
        return;
    }
    
    // 5. 尝试注册字体
    CFErrorRef error = NULL;
    if (!CTFontManagerRegisterFontsForURL((__bridge CFURLRef)fontURL, kCTFontManagerScopeProcess, &error)) {
        if (CFErrorGetCode(error) == kCTFontManagerErrorAlreadyRegistered) {
            NSLog(@"字体已注册，直接使用: %@", fontName);
            self.customFontName = fontName;
        } else {
            CFStringRef errorDescription = CFErrorCopyDescription(error);
            NSLog(@"❌ 字体注册失败: %@", errorDescription);
            CFRelease(errorDescription);
        }
        return;
    }
    
    NSLog(@"✅ 字体注册成功: %@", fontName);
    self.customFontName = fontName;
}
#pragma mark - 添加歌曲名称标签
- (void)addNowPlayingInfoSong {
    self.nowPlayingInfoSong = [[UILabel alloc] init];
    [self.nowPlayingInfoSong setMarqueeRunning:YES];  // 启用跑马灯效果
    [self.nowPlayingInfoSong setMarqueeEnabled:YES];  // 允许跑马灯
    // 根据布局样式设置对齐方式
    self.nowPlayingInfoSong.textAlignment = AlignmentCenter ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    if (self.customFontName && myfont) {
        self.nowPlayingInfoSong.font = [UIFont fontWithName:self.customFontName size:fontOfSize];
    } else {
        self.nowPlayingInfoSong.font = [UIFont systemFontOfSize:fontOfSize];
    }
    self.nowPlayingInfoSong.frame = CGRectMake(0, 0, tagLengthRP, fontOfSize);  // 设置frame
    // 根据模糊样式设置文字颜色
    self.nowPlayingInfoSong.textColor = [UIColor colorWithHexString:textColor];
    self.nowPlayingInfoSong.clipsToBounds = NO;
    self.nowPlayingInfoSong.isAccessibilityElement = YES;  // 启用无障碍访问
    self.nowPlayingInfoSong.accessibilityHint = @"当前播放歌曲的名称。";  // 无障碍提示
    [self.labelsStackView addArrangedSubview:self.nowPlayingInfoSong];  // 添加到堆栈视图
    
    // 设置约束
    self.nowPlayingInfoSong.translatesAutoresizingMaskIntoConstraints = false;
    [self.nowPlayingInfoSong.widthAnchor constraintEqualToConstant:tagLengthRP].active = true;
    [self.nowPlayingInfoSong.heightAnchor constraintEqualToConstant:fontOfSize].active = true;
}

#pragma mark - 添加艺术家标签（与歌曲名标签类似）
- (void)addNowPlayingInfoArtist {
    self.nowPlayingInfoArtist = [[UILabel alloc] init];
    [self.nowPlayingInfoArtist setMarqueeRunning:YES];
    [self.nowPlayingInfoArtist setMarqueeEnabled:YES];
    self.nowPlayingInfoArtist.textAlignment = AlignmentCenter ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    if (self.customFontName && myfont) {
        self.nowPlayingInfoArtist.font = [UIFont fontWithName:self.customFontName size:fontOfSize - 3];
    } else {
        self.nowPlayingInfoArtist.font = [UIFont systemFontOfSize:fontOfSize - 3];
    }
    self.nowPlayingInfoArtist.frame = CGRectMake(0, 0, tagLengthRP, fontOfSize - 3);
    self.nowPlayingInfoArtist.alpha = 0.8;  // 设置透明度
    self.nowPlayingInfoArtist.textColor = [UIColor colorWithHexString:textColor];
    self.nowPlayingInfoArtist.clipsToBounds = NO;
    self.nowPlayingInfoArtist.isAccessibilityElement = YES;
    self.nowPlayingInfoArtist.accessibilityHint = @"当前播放歌曲的艺术家。";
    [self.labelsStackView addArrangedSubview:self.nowPlayingInfoArtist];
    
    self.nowPlayingInfoArtist.translatesAutoresizingMaskIntoConstraints = false;
    [self.nowPlayingInfoArtist.widthAnchor constraintEqualToConstant:tagLengthRP].active = true;
    [self.nowPlayingInfoArtist.heightAnchor constraintEqualToConstant:fontOfSize - 3].active = true;
}

#pragma mark - 添加专辑标签（与歌曲名标签类似）
- (void)addNowPlayingInfoAlbum {
    self.nowPlayingInfoAlbum = [[UILabel alloc] init];
    [self.nowPlayingInfoAlbum setMarqueeRunning:YES];
    [self.nowPlayingInfoAlbum setMarqueeEnabled:YES];
    self.nowPlayingInfoAlbum.textAlignment = AlignmentCenter ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    if (self.customFontName && myfont) {
        self.nowPlayingInfoAlbum.font = [UIFont fontWithName:self.customFontName size:fontOfSize - 3];
    } else {
        self.nowPlayingInfoAlbum.font = [UIFont systemFontOfSize:fontOfSize - 3];
    }
    self.nowPlayingInfoAlbum.frame = CGRectMake(0, 0, tagLengthRP, fontOfSize - 3);
    self.nowPlayingInfoAlbum.alpha = 0.8;  // 设置更低的透明度
    self.nowPlayingInfoAlbum.textColor = [UIColor colorWithHexString:textColor];
    self.nowPlayingInfoAlbum.clipsToBounds = NO;
    self.nowPlayingInfoAlbum.isAccessibilityElement = YES;
    self.nowPlayingInfoAlbum.accessibilityHint = @"当前播放歌曲的专辑。";
    [self.labelsStackView addArrangedSubview:self.nowPlayingInfoAlbum];
    
    self.nowPlayingInfoAlbum.translatesAutoresizingMaskIntoConstraints = false;
    [self.nowPlayingInfoAlbum.widthAnchor constraintEqualToConstant:tagLengthRP].active = true;
    [self.nowPlayingInfoAlbum.heightAnchor constraintEqualToConstant:fontOfSize - 3].active = true;
}

#pragma mark - 添加标签堆栈视图（包含歌曲名、艺术家、专辑标签）
- (void)addLabelsStackView {
    for (UIView *subview in self.labelsStackView.arrangedSubviews) {
        [self.labelsStackView removeArrangedSubview:subview];
        [subview removeFromSuperview];
    }
    self.labelsStackView = [UIStackView new];
    self.labelsStackView.frame = CGRectMake(self.center.x+lyricsLabelX+positionXRP+75, self.center.y+lyricsLabelX+positionYRP+30, tagLengthRP, fontOfSize*2-3+spac);
    self.labelsStackView.transform = CGAffineTransformMakeScale(0.8, 0.8);  // 缩放效果
    self.labelsStackView.axis = UILayoutConstraintAxisVertical;  // 垂直排列
    self.labelsStackView.alignment = UIStackViewAlignmentFill;
    self.labelsStackView.distribution = UIStackViewDistributionEqualSpacing;
    self.labelsStackView.spacing = spac;  // 子视图间距
    self.labelsStackView.layoutMarginsRelativeArrangement = YES;
    // 添加各个标签
    BOOL hasSong = self.currentSongTitle.length > 0 &&
        [[self.currentSongTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0;

    BOOL hasArtist = self.currentArtist.length > 0 &&
        [[self.currentArtist stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0;

    BOOL hasAlbum = self.currentAlbum.length > 0 &&
        [[self.currentAlbum stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0;

    if (hasSong) {
        [self addNowPlayingInfoSong];
    }

    if (hasArtist) {
        [self addNowPlayingInfoArtist];
    } else if (hasAlbum) {
        // 只有在没有 artist 时才添加 album
        [self addNowPlayingInfoAlbum];
    }
    self.labelsStackView.translatesAutoresizingMaskIntoConstraints = false;
    self.labelsStackView.userInteractionEnabled = YES; // ✅ 必须开启交互
    [self addSubview:self.labelsStackView];  // 添加到视图
    //[self.labelsStackView.heightAnchor constraintEqualToConstant:60].active = true;
    //[self.labelsStackView.widthAnchor constraintEqualToConstant:tagLengthRP].active = true;
    // 根据布局样式设置位置
    [self.labelsStackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:lyricsLabelX+positionXRP+75].active = true;
    [self.labelsStackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:lyricsLabelY+positionYRP+40].active = true;
        // 替换原有点击手势为拖动手势（兼容点击）
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] 
        initWithTarget:self action:@selector(playPause)];
    [self.labelsStackView addGestureRecognizer:tapGesture];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] 
        initWithTarget:self 
        action:@selector(handleAlbumGesture:)];
    pan.minimumNumberOfTouches = 1;
    pan.maximumNumberOfTouches = 1;
    [self.labelsStackView addGestureRecognizer:pan];
}

#pragma mark - 按钮动画
// 按钮按下时的动画
- (void)buttonTouchDown:(UIButton *)button {
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        button.transform = CGAffineTransformMakeScale(0.7, 0.7);
    } completion:nil];
}


#pragma mark - 按钮释放时的弹簧动画
- (void)buttonTouchUp:(UIButton *)button {
    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        button.transform = CGAffineTransformIdentity;
    } completion:nil];
}
#pragma mark - 添加上一首按钮
- (void)addPreviousButton {
    self.previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    // 禁用按钮高亮状态下的自动调整效果
    self.previousButton.adjustsImageWhenHighlighted = NO;
    self.previousButton.frame = CGRectMake(0, 0, buttonSize, buttonSize);

    [self.previousButton setTitle:@"" forState:UIControlStateNormal];  // 无文字
    // 设置按钮图标
    NSBundle *tweakBundle = [NSBundle bundleWithPath:presetThemesPath];
    // 加载图片
    UIImage *customImage = [UIImage imageNamed:@"previous" 
                                inBundle:tweakBundle 
           compatibleWithTraitCollection:nil];
    [self.previousButton setImage:[customImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] 
                        forState:UIControlStateNormal];
        // 添加按钮按下事件
    [self.previousButton addTarget:self 
                           action:@selector(buttonTouchDown:) 
                 forControlEvents:UIControlEventTouchDown];
    
    // 添加按钮释放事件（包括内部释放、外部释放和取消事件）
    [self.previousButton addTarget:self 
                           action:@selector(buttonTouchUp:) 
                 forControlEvents:UIControlEventTouchUpInside];
    [self.previousButton addTarget:self 
                           action:@selector(buttonTouchUp:) 
                 forControlEvents:UIControlEventTouchUpOutside];
    [self.previousButton addTarget:self 
                           action:@selector(buttonTouchUp:) 
                 forControlEvents:UIControlEventTouchCancel];
    // 添加点击事件
    [self.previousButton addTarget:self
                            action:@selector(previous)
                  forControlEvents:UIControlEventTouchUpInside];
                  
    self.previousButton.isAccessibilityElement = YES;
    self.previousButton.accessibilityHint = @"上一首按钮。";
    self.previousButton.imageView.contentMode = UIViewContentModeScaleAspectFit;// 设置图片内容模式为等比例适应
    self.previousButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;// 设置内容对齐方式为填充
    self.previousButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    [self.previousButton setContentMode:UIViewContentModeCenter];// 设置内容模式为中心
    [self.controlsStackView addArrangedSubview:self.previousButton];  // 添加到控制堆栈
    
    // 设置约束
    self.previousButton.translatesAutoresizingMaskIntoConstraints = false;
    [self.previousButton.widthAnchor constraintEqualToConstant:buttonSize].active = true;
    [self.previousButton.heightAnchor constraintEqualToConstant:buttonSize].active = true;
}

#pragma mark - 添加播放/暂停按钮
- (void)addPlayPauseButton {
    self.playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    // 禁用按钮高亮状态下的自动调整效果
    self.playPauseButton.adjustsImageWhenHighlighted = NO;
    [self.playPauseButton setTitle:@"" forState:UIControlStateNormal];
    self.playPauseButton.frame = CGRectMake(0, 0, buttonSize, buttonSize);
    // 添加按钮按下和释放事件（同上）
    [self.playPauseButton addTarget:self 
                            action:@selector(buttonTouchDown:) 
                  forControlEvents:UIControlEventTouchDown];
    [self.playPauseButton addTarget:self 
                            action:@selector(buttonTouchUp:) 
                  forControlEvents:UIControlEventTouchUpInside];
    [self.playPauseButton addTarget:self 
                            action:@selector(buttonTouchUp:) 
                  forControlEvents:UIControlEventTouchUpOutside];
    [self.playPauseButton addTarget:self 
                            action:@selector(buttonTouchUp:) 
                  forControlEvents:UIControlEventTouchCancel];
    
    // 添加点击事件
    [self.playPauseButton addTarget:self
                             action:@selector(playPause)
                   forControlEvents:UIControlEventTouchUpInside];
    self.playPauseButton.isAccessibilityElement = YES;
    self.playPauseButton.accessibilityHint = @"播放/暂停按钮。";
    self.playPauseButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.playPauseButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.playPauseButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    [self.playPauseButton setContentMode:UIViewContentModeCenter];
    [self.controlsStackView addArrangedSubview:self.playPauseButton];
    
    // 设置约束
    self.playPauseButton.translatesAutoresizingMaskIntoConstraints = false;
    [self.playPauseButton.widthAnchor constraintEqualToConstant:buttonSize].active = true;
    [self.playPauseButton.heightAnchor constraintEqualToConstant:buttonSize].active = true;
}

#pragma mark - 添加下一首按钮
- (void)addNextButton {
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    // 禁用按钮高亮状态下的自动调整效果
    self.nextButton.adjustsImageWhenHighlighted = NO;
    self.nextButton.frame = CGRectMake(0, 0, buttonSize, buttonSize);
    [self.nextButton setTitle:@"" forState:UIControlStateNormal];
    // 设置按钮图标
    NSBundle *tweakBundle = [NSBundle bundleWithPath:presetThemesPath];
    // 加载图片
    UIImage *customImage = [UIImage imageNamed:@"next" 
                                inBundle:tweakBundle 
           compatibleWithTraitCollection:nil];
    [self.nextButton setImage:[customImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] 
                        forState:UIControlStateNormal];
    // 添加按钮按下和释放事件（同上）
    [self.nextButton addTarget:self 
                       action:@selector(buttonTouchDown:) 
             forControlEvents:UIControlEventTouchDown];
    [self.nextButton addTarget:self 
                       action:@selector(buttonTouchUp:) 
             forControlEvents:UIControlEventTouchUpInside];
    [self.nextButton addTarget:self 
                       action:@selector(buttonTouchUp:) 
             forControlEvents:UIControlEventTouchUpOutside];
    [self.nextButton addTarget:self 
                       action:@selector(buttonTouchUp:) 
             forControlEvents:UIControlEventTouchCancel];
    // 添加点击事件
    [self.nextButton addTarget:self
                        action:@selector(next)
              forControlEvents:UIControlEventTouchUpInside];
    self.nextButton.isAccessibilityElement = YES;
    self.nextButton.accessibilityHint = @"下一首按钮。";
    self.nextButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.nextButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.nextButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    [self.nextButton setContentMode:UIViewContentModeCenter];
    [self.controlsStackView addArrangedSubview:self.nextButton];
    
    // 设置约束
    self.nextButton.translatesAutoresizingMaskIntoConstraints = false;
    [self.nextButton.widthAnchor constraintEqualToConstant:buttonSize].active = true;
    [self.nextButton.heightAnchor constraintEqualToConstant:buttonSize].active = true;
}

#pragma mark - 添加控制按钮堆栈视图（包含上一首、播放/暂停、下一首按钮）
- (void)addControlsStackView {
    self.controlsStackView = [UIStackView new];// 创建新的堆栈视图
    self.controlsStackView.frame = CGRectMake(self.center.x+buttonOffsetX+positionXRP+75,self.center.y+buttonOffsetY+positionYRP+84,50 + buttonSpacing * 2 + 3 * buttonSize,buttonSize);
    self.controlsStackView.transform = CGAffineTransformMakeScale(0.8, 0.8);  // 缩放效果
    self.controlsStackView.axis = UILayoutConstraintAxisHorizontal;  // 水平排列
    self.controlsStackView.alignment = UIStackViewAlignmentFill;// 设置对齐方式为填充
    self.controlsStackView.distribution = UIStackViewDistributionEqualSpacing;// 设置分布方式为等间距
    self.controlsStackView.spacing = buttonSpacing;  // 子视图间距
    self.controlsStackView.layoutMarginsRelativeArrangement = YES;// 启用布局边距相对排列
    self.controlsStackView.translatesAutoresizingMaskIntoConstraints = false;// 禁用自动调整掩码转换
    // 添加各个按钮
    [self addPreviousButton];
    [self addPlayPauseButton];
    [self addNextButton];
    [self addSubview:self.controlsStackView];  // 添加到视图
    self.controlsStackView.translatesAutoresizingMaskIntoConstraints = false;
    [self.controlsStackView.heightAnchor constraintEqualToConstant:buttonSize].active = true;
    [self.controlsStackView.widthAnchor constraintEqualToConstant:50 + buttonSpacing * 2 + 3 * buttonSize].active = true;
    // 根据布局样式设置位置
    [self.controlsStackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:buttonOffsetX+positionXRP+75].active = true;
    [self.controlsStackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:buttonOffsetY+positionYRP+84].active = true;
}

#pragma mark - 播放状态变化回调
- (void)playingDidChange:(NSNotification *)notification {
    // 获取当前播放状态并更新按钮图标
    MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_get_main_queue(), ^(Boolean isPlayingNow){
            if (isPlayingNow == YES) {
                // 正在播放时显示暂停图标
                NSBundle *tweakBundle = [NSBundle bundleWithPath:presetThemesPath];
                // 加载图片
                UIImage *customImage = [UIImage imageNamed:@"pause" 
                                        inBundle:tweakBundle 
                    compatibleWithTraitCollection:nil];
                [self.playPauseButton setImage:[customImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] 
                                    forState:UIControlStateNormal];
                [self.progressView startTimer]; // 开始播放时启动定时器
                if (showOverlay) {
                    [self playAnimation];
                }
                // 只有当albumRotating为YES时才处理旋转逻辑
                if (albumRotating && albumCircleView) {
                    [self startRotatingContainer];
                } else {
                    [self pauseRotatingContainer];
                }
                if (self.mshfView) {
                    [self.mshfView start];
                }
            } else {
                // 暂停时显示播放图标
                NSBundle *tweakBundle = [NSBundle bundleWithPath:presetThemesPath];
                // 加载图片
                UIImage *customImage = [UIImage imageNamed:@"play" 
                                        inBundle:tweakBundle 
                    compatibleWithTraitCollection:nil];
                [self.playPauseButton setImage:[customImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] 
                                    forState:UIControlStateNormal];
                [self.progressView stopTimer]; // 暂停时停止定时器
                if (showOverlay) {
                    [self pauseAnimation];
                }
                if (albumRotating && albumCircleView) {
                    [self pauseRotatingContainer];
                }
                if (self.mshfView) {
                    [self.mshfView stop];
                }
            }
        });
}

#pragma mark - 更新过渡动画效果
- (void)updateTransition {
    // 创建专辑封面的淡入淡出动画
    CATransition *transition = [CATransition animation];
    transition.duration = 1.0f;  // 动画时长1秒
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];  // 缓入缓出
    transition.type = kCATransitionFade;  // 淡入淡出效果

    [self.artworkContainerView.artworkView.layer addAnimation:transition forKey:nil];
    /*
    // 创建背景图片的淡入淡出动画
    CATransition *transitionBG = [CATransition animation];
    transitionBG.duration = 1.0f;
    transitionBG.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transitionBG.type = kCATransitionFade;

    [self.backgroundImageView.layer addAnimation:transitionBG forKey:nil];
    */
}

#pragma mark - 按钮事件
/*
- **`UIImpactFeedbackStyle`** 可选：
    UIImpactFeedbackStyleLight,   // 最轻，适合按钮按下
    UIImpactFeedbackStyleMedium,  // 中等，常用
    UIImpactFeedbackStyleHeavy,   // 比较强
    UIImpactFeedbackStyleSoft API_AVAILABLE(ios(13.0)),   // 柔和、有弹性感
    UIImpactFeedbackStyleRigid API_AVAILABLE(ios(13.0)),  // 硬、直接的震动
  */
#pragma mark - 播放/暂停按钮点击事件
- (void)playPause {
    MRMediaRemoteSendCommand(kMRTogglePlayPause, nil);  // 发送播放/暂停命令
    if (Vibration) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];//预热反馈系统
        [generator impactOccurred];
        //AudioServicesPlaySystemSound(1519);// 播放点击音效
    }
}

#pragma mark - 下一首按钮点击事件
-(void)next {
    MRMediaRemoteSendCommand(kMRNextTrack, nil);  // 发送下一首命令
    if (Vibration) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];//预热反馈系统
        [generator impactOccurred];
    }
}

#pragma mark - 上一首按钮点击事件
-(void)previous {
    MRMediaRemoteSendCommand(kMRPreviousTrack, nil);  // 发送上一首命令
    if (Vibration) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];//预热反馈系统
        [generator impactOccurred];
    }
}
#pragma mark - 进度条
- (void)addProgressView {
    self.progressView = [[LHHNowPlayingProgressView alloc] init];
    if (Progress) {
        self.progressView.hidden = NO; 
    } else {
        self.progressView.hidden = YES; 
    }
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.progressView];

    // 先设置宽度和水平居中
    [self.progressView.widthAnchor constraintEqualToConstant:progresswidth].active = YES;
    [self.progressView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:positionXRP+progressX].active = YES;
    // 然后设置垂直位置
    [self.progressView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:positionYRP+progressY].active = YES;
    // 最后设置高度
    [self.progressView.heightAnchor constraintEqualToConstant:40].active = YES;
    // 修改轨道高度
    [self.progressView.remainingTrack.heightAnchor constraintEqualToConstant:ToConstant].active = YES; // 高度5pt
    [self.progressView.elapsedTrack.heightAnchor constraintEqualToConstant:ToConstant].active = YES; // 高度5pt
    // 修改时间标签的字体大小（例如改为 15）
    self.progressView.elapsedLabel.font = [UIFont boldSystemFontOfSize:FontOfSize];
    self.progressView.remainingLabel.font = [UIFont boldSystemFontOfSize:FontOfSize];

    // 样式设置
    self.progressView.elapsedTrack.backgroundColor = [UIColor colorWithHexString:elapsedColor];
    self.progressView.remainingTrack.backgroundColor = [UIColor colorWithHexString:remainingColor];
    self.progressView.knobView.knob.backgroundColor = [UIColor colorWithHexString:knobColor];
    self.progressView.elapsedLabel.textColor = [UIColor colorWithHexString:elapsedLabelColor];
    self.progressView.remainingLabel.textColor = [UIColor colorWithHexString:remainingLabelColor];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.progressView updateNowPlayingImmediately]; // 立即获取当前播放信息
            [self.progressView startTimer]; // 开始计时器实时更新
        });
}
#pragma mark - 更新图片和信息
- (void)updateImage {
 // 添加防抖机制，防止频繁更新
 /*
    static NSTimeInterval lastUpdateTime = 0;
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if (now - lastUpdateTime < 0.01) { // 限制最低更新频率为0.5秒
        return;
    }
    lastUpdateTime = now;
    */
    // 获取当前播放信息
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
        if (result) {
            NSDictionary *dictionary = (__bridge NSDictionary *)result;
            // 获取歌曲信息
            NSString *songName = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle];
            NSString *artistName = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist];
            NSString *albumName = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoAlbum];
            NSData *artworkData = [dictionary objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData];
            NSNumber *duration = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDuration];
            NSNumber *elapsed = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime];
            // 避免重复更新相同内容
            
            if (![self.currentSongTitle isEqualToString:songName] && 
                [self.currentArtist isEqualToString:artistName]) {
                // 更新歌曲名称
                if (songName != nil) {
                    self.nowPlayingInfoSong.text = [NSString stringWithFormat:@"%@", songName];
                    self.nowPlayingInfoSong.accessibilityLabel = [NSString stringWithFormat:@"%@", songName];
                    [self setHidden:NO];// 显示视图
                } else {
                    self.nowPlayingInfoSong.text = @" ";
                    self.nowPlayingInfoSong.accessibilityLabel = @" ";
                    [self setHidden:YES];// 隐藏视图
                }
                return;
            }
            
                // 在回调里赋值
                self.currentSongTitle = songName ?: @"";
                self.currentArtist = artistName ?: @"";
                self.currentAlbum = albumName ?: @"";
                // 更新标签
                [self addLabelsStackView];
                // 更新进度条
                if (duration && elapsed) {
                    // 如果用户正在交互，不更新进度
                    if (!self.progressView.isTracking) {
                        self.progressView.duration = [duration doubleValue];
                        self.progressView.elapsedTime = [elapsed doubleValue];
                    }
                }
                // 更新专辑封面和背景图片
                if (cover) {
                    // 使用 presetThemesPath 下的 cover.png
                    NSString *coverPath = [presetThemesPath stringByAppendingPathComponent:@"cover.png"];
                    self.artworkContainerView.artworkView.image = [UIImage imageWithContentsOfFile:coverPath];
                    self.backgroundImageView.image = [UIImage imageWithContentsOfFile:[presetThemesPath stringByAppendingPathComponent:@"bg.png"]];
                    [self updateTransition];// 更新过渡动画
                } else if (artworkData != nil) {
                    // 使用系统音乐封面
                        UIImage *artwork = [UIImage imageWithData:artworkData];
                            self.artworkContainerView.artworkView.image = artwork;
                            self.backgroundImageView.image = [UIImage imageWithContentsOfFile:[presetThemesPath stringByAppendingPathComponent:@"bg.png"]];
                            [self updateTransition];// 更新过渡动画
                }
            
                // 更新歌曲名
                if (songName != nil) {
                    self.nowPlayingInfoSong.text = [NSString stringWithFormat:@"%@", songName];
                    self.nowPlayingInfoSong.accessibilityLabel = [NSString stringWithFormat:@"%@", songName];
                    [self setHidden:NO];  // 显示视图
                } else {
                    self.nowPlayingInfoSong.text = @" ";
                    self.nowPlayingInfoSong.accessibilityLabel = @" ";
                    [self setHidden:YES];  // 隐藏视图
                }
                
                // 更新艺术家名
                if (artistName != nil) {
                    self.nowPlayingInfoArtist.text = [NSString stringWithFormat:@"%@", artistName];
                    self.nowPlayingInfoArtist.accessibilityLabel = [NSString stringWithFormat:@"%@", artistName];
                } else {
                    self.nowPlayingInfoArtist.text = @" ";
                    self.nowPlayingInfoArtist.accessibilityLabel = @" ";
                }
                
                // 更新专辑名
                if (albumName != nil) {
                    self.nowPlayingInfoAlbum.text = [NSString stringWithFormat:@"%@", albumName];
                    self.nowPlayingInfoAlbum.accessibilityLabel = [NSString stringWithFormat:@"%@", albumName];
                } else {
                    self.nowPlayingInfoAlbum.text = @" ";
                    self.nowPlayingInfoAlbum.accessibilityLabel = @" ";
                }
            
        } else {
            [self.mshfView stop];
            // 没有播放信息时显示默认图片
            self.artworkContainerView.artworkView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@DefaultContainerArtwork.png", bundlePath]];
            self.backgroundImageView.image = [UIImage imageWithContentsOfFile:[presetThemesPath stringByAppendingPathComponent:@"bg.png"]];
            // 停止进度条更新
            [self.progressView stopTimer]; 
        }
    });
}
- (void)dealloc {
    // 确保停止定时器
    [self.mshfView stop];
    [self.progressView stopTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

#pragma mark - 构造函数（在加载时执行）
%ctor {
    BOOL shouldLoad = NO;
    // 获取进程参数
    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger count = args.count;
    if (count != 0) {
        NSString *executablePath = args[0];
        if (executablePath) {
            // 判断进程类型
            NSString *processName = [executablePath lastPathComponent];
            BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];  // 主屏幕
            BOOL isPreferences = [processName isEqualToString:@"Preferences"];  // 设置
            BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;  // 普通应用
            BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;  // 文件提供者
            // 需要跳过的进程
            BOOL skip = [processName isEqualToString:@"AdSheet"]
            || [processName isEqualToString:@"CoreAuthUI"]
            || [processName isEqualToString:@"InCallService"]
            || [processName isEqualToString:@"MessagesNotificationViewService"]
            || [executablePath rangeOfString:@".appex/"].location != NSNotFound;  // 应用扩展
            // 确定是否需要加载
            if (!isFileProvider && (isSpringBoard || isApplication || isPreferences) && !skip) {
                shouldLoad = YES;
            }
        }
    }
    if (shouldLoad) {
        loadPreferences(); // 加载首选项
        // 添加首选项变化监听
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPreferences, (CFStringRef)preferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    }
}