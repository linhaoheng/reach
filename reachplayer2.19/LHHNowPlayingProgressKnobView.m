#import "LHHNowPlayingProgressKnobView.h"

@implementation LHHNowPlayingProgressKnobView

- (instancetype)init {
    self = [super init];
    
    if (self) {
        // 初始化旋钮视图（实际显示的旋钮）
        self.knob = [[UIView alloc] init];
        self.knob.backgroundColor = [UIColor blackColor]; // 设置旋钮背景颜色为黑色
        self.knob.layer.cornerRadius = 3.5; // 设置旋钮的圆角半径为3.5pt，使其呈现圆形
        self.knob.layer.shadowColor = [UIColor blackColor].CGColor; // 设置阴影颜色为黑色
        self.knob.layer.shadowOpacity = 0.2; // 设置阴影的不透明度为0.2
        self.knob.layer.shadowRadius = 3; // 设置阴影的模糊半径为3pt
        self.knob.layer.shadowOffset = CGSizeMake(0, 1); // 设置阴影的偏移量为上偏移1pt
        self.knob.translatesAutoresizingMaskIntoConstraints = NO; // 启用自动布局
        [self addSubview:self.knob]; // 将旋钮添加到当前视图
        
        // 初始化点击区域视图（用于扩大旋钮的可点击区域）
        self.hitbox = [[UIView alloc] init];
        self.hitbox.translatesAutoresizingMaskIntoConstraints = NO; // 启用自动布局
        [self addSubview:self.hitbox]; // 将点击区域添加到当前视图
        
        // 设置点击区域的布局约束
        // 点击区域的左侧与当前视图的左侧对齐
        [self.hitbox.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
        // 点击区域的顶部与当前视图的顶部对齐
        [self.hitbox.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        // 点击区域的宽度固定为19pt
        [self.hitbox.widthAnchor constraintEqualToConstant:19].active = YES;
        // 点击区域的高度固定为19pt
        [self.hitbox.heightAnchor constraintEqualToConstant:19].active = YES;
        
        // 设置旋钮在点击区域内的布局约束
        // 旋钮的中心X轴与点击区域的中心X轴对齐，使旋钮在点击区域内水平居中
        [self.knob.centerXAnchor constraintEqualToAnchor:self.hitbox.centerXAnchor].active = YES;
        // 旋钮的中心Y轴与点击区域的中心Y轴对齐，使旋钮在点击区域内垂直居中
        [self.knob.centerYAnchor constraintEqualToAnchor:self.hitbox.centerYAnchor].active = YES;
        // 旋钮的宽度固定为7pt
        [self.knob.widthAnchor constraintEqualToConstant:7].active = YES;
        // 旋钮的高度固定为7pt
        [self.knob.heightAnchor constraintEqualToConstant:7].active = YES;
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // 当用户开始触摸旋钮时，执行缩放动画，使旋钮放大到1.5倍
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.transform = CGAffineTransformMakeScale(1.5, 1.5); // 放大旋钮
    }
                     completion:nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // 当用户结束触摸旋钮时，执行缩放动画，使旋钮恢复到原始大小
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.transform = CGAffineTransformMakeScale(1, 1); // 恢复旋钮大小
    }
                     completion:nil];
}

@end
