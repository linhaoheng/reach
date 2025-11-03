#import "LHHSliderCell.h"

@implementation LHHSliderCell {
    UIStackView *_stackView;        // 主垂直堆栈视图（标题+滑块区域）
    UIStackView *_sliderStackView;  // 水平堆栈视图（滑块+数值标签）
    UILabel *_sliderLabel;          // 滑块标题标签
    UILabel *_valueLabel;           // 显示当前值的标签
    UIButton *_minusButton;   // 减号按钮
    UIButton *_plusButton;    // 加号按钮
    NSTimer *_incrementTimer;
    NSTimer *_decrementTimer;
}

// 初始化方法
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier];

    if(self) {
        _feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [_feedbackGenerator prepare];
        
        // 设置单元格高度为56
        [specifier setProperty:@50 forKey:@"height"];

        // 获取本地化资源
        NSBundle *bundle = [specifier.target bundle];
        NSString *label = [specifier propertyForKey:@"label"];
        NSString *localizationTable = [specifier propertyForKey:@"localizationTable"];

        // 创建滑块标题标签（使用specifier的label属性）
        _sliderLabel = [[UILabel alloc] init];
        //_sliderLabel.textColor = [UIColor labelColor];
        //_sliderLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium]; // 常规字体
        _sliderLabel.text = [bundle localizedStringForKey:label value:label table:localizationTable]; // 本地化文本
        
        _sliderLabel.translatesAutoresizingMaskIntoConstraints = NO; // 禁用自动布局转换


        // 1. 创建减号按钮（带圆角和背景）
        
        _minusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        //[_minusButton setTitle:@"-" forState:UIControlStateNormal]; // 使用更粗的减号符号
        UIImageSymbolConfiguration *minusConfig = [UIImageSymbolConfiguration configurationWithPointSize:7 weight:UIImageSymbolWeightBold];
        [_minusButton setImage:[UIImage systemImageNamed:@"minus" withConfiguration:minusConfig] forState:UIControlStateNormal];
        //[_minusButton setTitle:nil forState:UIControlStateNormal]; // 清除文字
        //[_minusButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _minusButton.backgroundColor = [UIColor colorWithRed:248/255.0 green:248/255.0 blue:248/255.0 alpha:1.0];
        _minusButton.layer.cornerRadius = 5.0; // 圆角
        _minusButton.layer.masksToBounds = YES; // 裁剪超出圆角的部分
        _minusButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium]; // 加粗字体
        _minusButton.adjustsImageWhenHighlighted = YES;
        [_minusButton addTarget:self action:@selector(decrementValue) forControlEvents:UIControlEventTouchUpInside];
        UILongPressGestureRecognizer *minusLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMinusLongPress:)];
        [_minusButton addGestureRecognizer:minusLongPress];

        // 2. 创建加号按钮（样式与减号对称）
        _plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        //[_plusButton setTitle:@"+" forState:UIControlStateNormal];
        //[_plusButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        UIImageSymbolConfiguration *plusConfig = [UIImageSymbolConfiguration configurationWithPointSize:7 weight:UIImageSymbolWeightBold];
        [_plusButton setImage:[UIImage systemImageNamed:@"plus" withConfiguration:plusConfig] forState:UIControlStateNormal];
        //[_plusButton setTitle:nil forState:UIControlStateNormal]; // 清除文字
        _plusButton.backgroundColor = [UIColor colorWithRed:248/255.0 green:248/255.0 blue:248/255.0 alpha:1.0];
        _plusButton.layer.cornerRadius = 5.0;
        _plusButton.layer.masksToBounds = YES;
        _plusButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [_plusButton addTarget:self action:@selector(incrementValue) forControlEvents:UIControlEventTouchUpInside];
        UILongPressGestureRecognizer *plusLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePlusLongPress:)];
        [_plusButton addGestureRecognizer:plusLongPress];
        
        // 3. 固定按钮大小（避免拉伸）
        [NSLayoutConstraint activateConstraints:@[
            [_minusButton.widthAnchor constraintEqualToConstant:20], // 宽度固定
            [_minusButton.heightAnchor constraintEqualToConstant:12], // 高度固定

            [_plusButton.widthAnchor constraintEqualToConstant:20],
            [_plusButton.heightAnchor constraintEqualToConstant:12]
        ]];









        UISlider *slider = (UISlider *)self.control;
        //slider.minimumTrackTintColor = [UIColor systemBlueColor];  // 左侧滑轨蓝色


        // 创建数值显示标签
        _valueLabel = [[UILabel alloc] init];
        //_valueLabel.textColor = [UIColor systemBlueColor];
        _valueLabel.font = [UIFont monospacedDigitSystemFontOfSize:10 weight:UIFontWeightBold]; // 等宽数字字体
        _valueLabel.textAlignment = NSTextAlignmentRight; // 右对齐防止跳动
        float initialValue = [[specifier performGetter] floatValue];
        _valueLabel.text = [NSString stringWithFormat:@"%.02f", initialValue]; // 显示初始值
        NSString *maxWidthText = @"-2000.00";
        CGFloat maxValueWidth = [maxWidthText sizeWithAttributes:@{NSFontAttributeName: _valueLabel.font}].width;

        // 4. 固定宽度约束（无需清空文本）
        [_valueLabel.widthAnchor constraintEqualToConstant:maxValueWidth].active = YES;

        _valueLabel.userInteractionEnabled = YES; // 允许用户交互（用于点击事件）



        // 创建水平堆栈视图（包含滑块和数值标签）
        _sliderStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_sliderLabel, _minusButton, slider, _plusButton, _valueLabel]];
        _sliderStackView.alignment = UIStackViewAlignmentCenter; // 居中对齐
        _sliderStackView.axis = UILayoutConstraintAxisHorizontal; // 水平布局
        _sliderStackView.distribution = UIStackViewDistributionFill; // 填充分布
        _sliderStackView.spacing = 5; // 子视图间距5点
        _sliderStackView.translatesAutoresizingMaskIntoConstraints = NO;

        // 创建主垂直堆栈视图（包含标题和滑块区域）
        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_sliderStackView]];
        _stackView.alignment = UIStackViewAlignmentCenter; // 居中对齐
        _stackView.axis = UILayoutConstraintAxisVertical; // 垂直布局
        _stackView.distribution = UIStackViewDistributionEqualCentering; // 等间距分布
        _stackView.spacing = 0; // 子视图间距0点
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_stackView]; // 添加到单元格内容视图

        // 设置自动布局约束
        [NSLayoutConstraint activateConstraints:@[
            // 堆栈视图填充单元格（带边距）
            [_stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:0],
            [_stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
            [_stackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
            [_stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:0],

            // 滑块区域宽度与堆栈视图相同
            [_sliderStackView.widthAnchor constraintEqualToAnchor:_stackView.widthAnchor],

            // 数值标签高度与滑块区域相同
            [_valueLabel.heightAnchor constraintEqualToAnchor:_sliderStackView.heightAnchor],
        ]];

        // 添加滑块值变化事件（用于更新数值标签）
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventTouchDragInside];
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventTouchDragOutside];
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

        // 为数值标签添加点击手势（用于输入自定义值）
        UITapGestureRecognizer *enterCustomValueTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setCustomSliderValue)];
        enterCustomValueTap.numberOfTapsRequired = 1; // 单击触发
        [_valueLabel addGestureRecognizer:enterCustomValueTap];
    }

    return self;
}

- (void)handleMinusLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self startDecrementTimer];
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [self stopDecrementTimer];
    }
}

- (void)handlePlusLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self startIncrementTimer];
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [self stopIncrementTimer];
    }
}

- (void)startDecrementTimer {
    [self stopDecrementTimer];
    _decrementTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(decrementValue) userInfo:nil repeats:YES];
}

- (void)stopDecrementTimer {
    [_decrementTimer invalidate];
    _decrementTimer = nil;
}

- (void)startIncrementTimer {
    [self stopIncrementTimer];
    _incrementTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(incrementValue) userInfo:nil repeats:YES];
}

- (void)stopIncrementTimer {
    [_incrementTimer invalidate];
    _incrementTimer = nil;
}

// 加号按钮（+）逻辑
- (void)incrementValue {
    UISlider *slider = (UISlider *)self.control;
    float currentValue = slider.value;
    float newValue;

    if (slider.maximumValue <= 1.0f) {
        // 情况1：最大值≤1，固定步长0.01
        newValue = currentValue + 0.01f;
    } else if (slider.maximumValue <= 10.0f) {
        // 情况2：1<最大值≤10，取整到下一个0.1
        newValue = ceilf(currentValue * 10) / 10;
        if (newValue <= currentValue) {
            newValue = currentValue + 0.1f;
        }
    } else {
        // 情况3：最大值>10，取整到下一个整数
        newValue = ceilf(currentValue);
        if (newValue <= currentValue) {
            newValue = currentValue + 1.0f;
        }
    }
    
    newValue = MIN(newValue, slider.maximumValue);
    slider.value = newValue;
    [self.specifier performSetterWithValue:@(newValue)];
    [self sliderValueChanged:slider];
    // 触发震动
}

// 减号按钮（-）逻辑
- (void)decrementValue {
    UISlider *slider = (UISlider *)self.control;
    float currentValue = slider.value;
    float newValue;
    
    if (slider.maximumValue <= 1.0f) {
        // 情况1：最大值≤1，固定步长0.01
        newValue = currentValue - 0.01f;
    } else if (slider.maximumValue <= 10.0f) {
        // 情况2：1<最大值≤10，取整到当前0.1
        newValue = floorf(currentValue * 10) / 10;
        if (newValue >= currentValue) {
            newValue = currentValue - 0.1f;
        }
    } else {
        // 情况3：最大值>10，取整到当前整数
        newValue = floorf(currentValue);
        if (newValue >= currentValue) {
            newValue = currentValue - 1.0f;
        }
    }
    
    newValue = MAX(newValue, slider.minimumValue);
    slider.value = newValue;
    [self.specifier performSetterWithValue:@(newValue)];
    [self sliderValueChanged:slider];

}


// 弹出输入框让用户输入自定义值
-(void)setCustomSliderValue {
    UISlider *slider = (UISlider *)self.control;
    //NSString *currentValue = [NSString stringWithFormat:@"%f", slider.value]; // 当前值保留0位小数

    // 创建输入弹窗
    UIAlertController *enterValueAlert = [UIAlertController alertControllerWithTitle:@"输入数值" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [enterValueAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDecimalPad; // 数字键盘
        textField.text = @""; // 显示当前值
        textField.textColor = self.tintColor; // 使用主题色
    }];

    // "设置"按钮
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = enterValueAlert.textFields[0];
        CGFloat newValue = [textField.text floatValue]; // 获取输入值

        // 检查数值范围
        if(newValue > slider.maximumValue) {
            newValue = slider.maximumValue; // 超过最大值则设为最大值
        } else if(newValue < slider.minimumValue) {
            newValue = slider.minimumValue; // 低于最小值则设为最小值
        }

        // 更新滑块值
        [self.specifier performSetterWithValue:[NSNumber numberWithFloat:newValue]];
        [slider setValue:newValue animated:YES];
        [self sliderValueChanged:slider]; // 更新显示
    }];

    // "取消"按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];

    [enterValueAlert addAction:confirmAction];
    [enterValueAlert addAction:cancelAction];

    // 显示弹窗（自动查找最顶层的视图控制器）
    UIViewController *rootViewController = self._viewControllerForAncestor ?: [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:enterValueAlert animated:YES completion:nil];
}

// 滑块值变化时更新数值标签
-(void)sliderValueChanged:(UISlider *)slider {
    static float lastValue = -1;// 存储上一次的值

    _valueLabel.text = [NSString stringWithFormat:@"%.02f", slider.value]; // 显示2位小数
    // 触发震动
    // 只有当值实际发生变化时才触发震动
    if (fabsf(lastValue - slider.value) > 0.009f) {
        [_feedbackGenerator selectionChanged];
        [_feedbackGenerator prepare]; // 准备下一次震动
    }
    lastValue = slider.value; // 更新存储的值

}

// 主题色变化时更新UI颜色
-(void)tintColorDidChange {
    [super tintColorDidChange];
    //_sliderLabel.textColor = self.tintColor; // 更新标题颜色
    _valueLabel.textColor = self.tintColor;  // 更新数值颜色
}

// 刷新单元格内容
-(void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
    [super refreshCellContentsWithSpecifier:specifier];
    
    // 如果支持tintColor，更新标签颜色
    if([self respondsToSelector:@selector(tintColor)]) {
        //_sliderLabel.textColor = self.tintColor;
        _valueLabel.textColor = self.tintColor;
    }
}
@end
