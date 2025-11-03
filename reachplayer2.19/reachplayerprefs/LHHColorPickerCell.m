//
//  LHHColorPickerCell.m
//
//  颜色选择器单元格的实现文件，提供颜色选择、转换和显示功能
//

#import "LHHColorPickerCell.h"


@implementation LHHColorPickerCell {
  UIColorPickerViewController *_colorPicker;  // 颜色选择器控制器
  UIColor *_currentColor;                    // 当前选择的颜色
  NSString *_fallbackHex;                    // 默认的十六进制颜色值
  BOOL _supportsAlpha;                       // 是否支持透明度

  UIView *_indicatorView;                    // 颜色指示器视图
  CAShapeLayer *_indicatorShape;             // 颜色指示器的形状层
}

/**
 * 初始化方法
 * @param style 单元格样式
 * @param identifier 重用标识符
 * @param specifier 配置信息
 */
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];

    if(self) {
        // 从specifier中获取配置参数
        _fallbackHex = [specifier propertyForKey:@"fallbackHex"];      // 默认颜色值(字符串格式)
        _supportsAlpha = [specifier propertyForKey:@"supportsAlpha"];  // 布尔值，决定颜色选择器是否支持透明度设置

        // 本地化处理：获取bundle和本地化字符串
        NSBundle *bundle = [specifier.target bundle];  // 获取specifier所属的bundle
        NSString *label = [specifier propertyForKey:@"label"];  // 获取原始标签文本
        NSString *localizationTable = [specifier propertyForKey:@"localizationTable"];  // 本地化表名
    
        // 初始化iOS 14+的颜色选择器视图控制器
        _colorPicker = [[UIColorPickerViewController alloc] init];
        _colorPicker.delegate = self;  // 设置代理为当前类
        _colorPicker.supportsAlpha = _supportsAlpha;  // 配置是否支持透明度
        _colorPicker.title = [bundle localizedStringForKey:label value:label table:localizationTable];  // 设置本地化标题

        // 创建右侧附件视图(29x29pt) - 用于显示颜色指示器
        _indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 29, 29)];
        _indicatorView.backgroundColor = [UIColor clearColor];  // 透明背景
        _indicatorView.clipsToBounds = NO;  // 允许子视图超出边界
        self.accessoryView = _indicatorView;  // 设置为单元格的附件视图

        // 1️⃣ 创建彩虹圆环(使用圆锥渐变实现)
        CAGradientLayer *rainbowLayer = [CAGradientLayer layer];
        rainbowLayer.frame = _indicatorView.bounds;  // 匹配指示器视图尺寸
        rainbowLayer.type = kCAGradientLayerConic;  // 圆锥渐变类型
        rainbowLayer.startPoint = CGPointMake(0.5, 0.5);  // 渐变中心点
        rainbowLayer.endPoint = CGPointMake(1, 1);  // 渐变结束点
        rainbowLayer.colors = @[  // 彩虹色数组
            (id)[UIColor yellowColor].CGColor,
            (id)[UIColor greenColor].CGColor,
            (id)[UIColor cyanColor].CGColor,
            (id)[UIColor blueColor].CGColor,
            (id)[UIColor purpleColor].CGColor,
            (id)[UIColor magentaColor].CGColor,
            (id)[UIColor redColor].CGColor,
            (id)[UIColor orangeColor].CGColor,
            (id)[UIColor yellowColor].CGColor

        ];

        // 使用蒙版创建圆环效果(挖空中心部分)
        CAShapeLayer *rainbowMask = [CAShapeLayer layer];
        UIBezierPath *outer = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 29, 29)];  // 外圆
        UIBezierPath *inner = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(_indicatorView.bounds, 2, 2)];  // 内圆(缩小2pt)
        [outer appendPath:inner];  // 组合两个路径
        rainbowMask.path = outer.CGPath;  // 设置蒙版路径
        rainbowMask.fillRule = kCAFillRuleEvenOdd;  // 使用奇偶填充规则
        rainbowLayer.mask = rainbowMask;  // 应用蒙版
        [_indicatorView.layer addSublayer:rainbowLayer];  // 添加到视图层级

        // 2️⃣ 创建透明缓冲圈(在外环和内圆之间形成2pt间隙)
        UIView *transparentRing = [[UIView alloc] initWithFrame:CGRectInset(_indicatorView.bounds, 2, 2)];  // 内缩2pt
        transparentRing.backgroundColor = [UIColor clearColor];  // 透明背景
        transparentRing.layer.cornerRadius = transparentRing.frame.size.width / 2.0;  // 圆形
        transparentRing.layer.borderWidth = 2;  // 2pt边框(透明)
        transparentRing.layer.borderColor = [UIColor clearColor].CGColor;  // 透明边框
        [_indicatorView addSubview:transparentRing];  // 添加为子视图
    /*
        // 3️⃣ 创建当前颜色显示圆(占据最大可用空间)
        UIView *colorCircle = [[UIView alloc] initWithFrame:CGRectInset(_indicatorView.bounds, 4.5, 4.5)];  // 内缩4.5pt
        colorCircle.backgroundColor = _currentColor;  // 设置为当前颜色
        colorCircle.layer.cornerRadius = colorCircle.frame.size.width / 2.0;  // 圆形
        colorCircle.layer.masksToBounds = YES;  // 裁剪超出部分
        [_indicatorView addSubview:colorCircle];  // 添加为子视图
    */
        // 创建颜色指示器的填充形状
        _indicatorShape = [CAShapeLayer layer];
        // 计算内缩后的矩形（与colorCircle相同逻辑）
        CGRect circleRect = CGRectInset(_indicatorView.bounds, 4, 4);
        // 创建圆形路径（cornerRadius设为宽度的一半）
        _indicatorShape.path = [UIBezierPath bezierPathWithRoundedRect:circleRect cornerRadius:circleRect.size.width / 2.0].CGPath;

        [_indicatorView.layer addSublayer:_indicatorShape];

        // 获取保存的颜色值(优先)或使用默认值，并更新UI显示
        NSString *hex = ([specifier performGetter]) ?: _fallbackHex;  // 使用Getter获取值，若无则用默认值
        _currentColor = [self colorFromHex:hex useAlpha:_supportsAlpha];  // 将HEX字符串转为UIColor
        _indicatorShape.fillColor = _currentColor.CGColor;                          // 设置指示器颜色

        self.detailTextLabel.text = [self legibleStringFromHex:hex];  // 在详情文本显示HEX值
    }

    return self;
}

/**
 * 设置选中状态
 * @param selected 是否选中
 * @param animated 是否使用动画
 */
-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if(selected) {
        [self presentColorPicker];  // 选中时显示颜色选择器
    } else {
        [super setSelected:selected animated:animated];
    }
}

/**
 * 显示颜色选择器
 */
- (void)presentColorPicker {
    _colorPicker.selectedColor = _currentColor;

    // 设置为 Popover 样式
    _colorPicker.modalPresentationStyle = UIModalPresentationPopover;
    /*
    // 获取 root controller
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIViewController *rootVC = self._viewControllerForAncestor ?: [UIApplication sharedApplication].keyWindow.rootViewController;
    #pragma clang diagnostic pop
    */

    UIViewController *rootVC = self._viewControllerForAncestor;
    if (!rootVC) {
        if (@available(iOS 13.0, *)) {
            NSSet<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes;
            for (UIScene *scene in scenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    rootVC = windowScene.windows.firstObject.rootViewController;
                    break;
                }
            }
        } else {
            rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        }
    }
    
    // ✅ 获取 popoverPresentationController
    UIPopoverPresentationController *popover = _colorPicker.popoverPresentationController;
    if (popover) {
        popover.sourceView = _indicatorView;                    // 指向当前 cell
        popover.sourceRect = _indicatorView.bounds;             // 以 cell 为锚点
        popover.permittedArrowDirections = UIPopoverArrowDirectionRight;         // 显示箭头
        //_colorPicker.preferredContentSize = CGSizeMake(320, 400);
        popover.backgroundColor = [UIColor systemBackgroundColor]; // 可选：背景色
    }

    // ✅ 弹出控制器
    [rootVC presentViewController:_colorPicker animated:YES completion:nil];
}



#pragma mark - UIColorPickerViewControllerDelegate Methods

/**
 * 颜色选择器选择了颜色后的回调
 * @param colorPicker 颜色选择器控制器
 */
-(void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)colorPicker {
    _currentColor = colorPicker.selectedColor;  // 更新当前颜色

    // 将颜色转换为十六进制字符串并保存
    NSString *selectedColorHex = [self hexFromColor:_currentColor useAlpha:_supportsAlpha];
    [self.specifier performSetterWithValue:selectedColorHex];

    // 更新指示器颜色（带动画效果）
    [UIView transitionWithView:_indicatorView duration:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _indicatorShape.fillColor = _currentColor.CGColor;
    } completion:nil];

    // 更新副标题文本（带淡入淡出效果）
    [UIView transitionWithView:self.detailTextLabel duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.detailTextLabel.text = [self legibleStringFromHex:selectedColorHex];
    } completion:nil];
}

#pragma mark - Converting Colors

/**
 * 将十六进制字符串转换为UIColor对象
 * @param hexString 十六进制颜色字符串
 * @param useAlpha 是否使用透明度
 * @return UIColor对象
 */
-(UIColor *)colorFromHex:(NSString *)hexString useAlpha:(BOOL)useAlpha {
    hexString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];  // 标准化处理

    // 处理带透明度的格式（如"FF0000:50"）
    if([hexString containsString:@":"] || hexString.length == 6) {
        NSArray *hexComponents = [hexString componentsSeparatedByString:@":"];
        CGFloat alpha = (hexComponents.count == 2) ? [[hexComponents lastObject] floatValue] / 100 : 1.0;
        hexString = [NSString stringWithFormat:@"%@%02X", [hexComponents firstObject], (int)(alpha * 255.0)];
    }

    // 解析十六进制值
    unsigned int hex = 0;
    [[NSScanner scannerWithString:hexString] scanHexInt:&hex];

    // 提取RGBA分量
    CGFloat r = ((hex & 0xFF000000) >> 24) / 255.0;
    CGFloat g = ((hex & 0x00FF0000) >> 16) / 255.0;
    CGFloat b = ((hex & 0x0000FF00) >> 8) / 255.0;
    CGFloat a = (useAlpha) ? ((hex & 0x000000FF) >> 0) / 255.0 : 0xFF;

    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

/**
 * 将UIColor对象转换为十六进制字符串
 * @param color UIColor对象
 * @param useAlpha 是否包含透明度
 * @return 十六进制颜色字符串
 */
-(NSString *)hexFromColor:(UIColor *)color useAlpha:(BOOL)useAlpha {
    CIColor *ciColor = [CIColor colorWithCGColor:color.CGColor];
    CGFloat r = ciColor.red;
    CGFloat g = ciColor.green;
    CGFloat b = ciColor.blue;
    CGFloat a = ciColor.alpha;

    // 生成包含透明度的十六进制字符串
    NSString *hexString = [NSString stringWithFormat:@"#%02X%02X%02X%02X", (int)(r * 255.0), (int)(g * 255.0), (int)(b * 255.0), (int)(a * 255.0)];

    // 如果不使用透明度，则移除最后两位
    if(!useAlpha) {
        hexString = [hexString substringToIndex:hexString.length - 2];
    }

    return hexString;
}

/**
 * 将十六进制字符串格式化为易读格式
 * @param hexString 原始十六进制字符串
 * @return 格式化后的字符串
 */
-(NSString *)legibleStringFromHex:(NSString *)hexString {
    hexString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];  // 标准化处理

    // 处理带透明度的格式
    if([hexString containsString:@":"]) {
        NSArray *hexComponents = [hexString componentsSeparatedByString:@":"];
        return [NSString stringWithFormat:@"#%@:%@", hexComponents[0], hexComponents[1]];
    } else if(hexString.length == 6) {
        return [NSString stringWithFormat:@"#%@", hexString];  // 标准6位格式
    }

    // 处理8位格式（带透明度）
    unsigned int hex = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&hex];

    return [NSString stringWithFormat:@"#%@:%.2f", [hexString substringToIndex:hexString.length - 2], ((hex & 0x000000FF) >> 0) / 255.0];
}

#pragma mark - Tint Color

/**
 * 色调颜色改变时的回调
 */
-(void)tintColorDidChange {
    [super tintColorDidChange];

    // 更新文本颜色
    self.textLabel.textColor = self.tintColor;
    self.textLabel.highlightedTextColor = self.tintColor;
}

/**
 * 使用specifier刷新单元格内容
 * @param specifier 配置信息
 */
-(void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
    [super refreshCellContentsWithSpecifier:specifier];

    if([self respondsToSelector:@selector(tintColor)]) {
        // 更新文本颜色
        self.textLabel.textColor = self.tintColor;
        self.textLabel.highlightedTextColor = self.tintColor;
    }
}

@end
