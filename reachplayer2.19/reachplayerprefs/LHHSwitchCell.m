#import "LHHSwitchCell.h"

@implementation LHHSwitchCell {
    UIButton *_infoButton;
    NSBundle *_bundle;
  }

#pragma mark - 按钮颜色
- (void)layoutSubviews {
    [super layoutSubviews];

    // 遍历 subviews 找 UISwitch
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UISwitch class]]) {
            UISwitch *sw = (UISwitch *)view;
            sw.onTintColor = [UIColor colorWithRed:0.9176 green:0.7098 blue:0.3137 alpha:1.0];
        }
    }
}


#pragma mark - 按钮信息
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier {
  self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier];

    //Add button next to cell
  if (self) {
        // 默认不显示信息按钮
        _infoButton = nil;
      // 检查 infoTitle 或 infoMessage 是否存在（即使内容为空）
              BOOL hasInfo = ([specifier propertyForKey:@"infoTitle"] != nil) ||
                             ([specifier propertyForKey:@"infoMessage"] != nil);

        // 检查 specifier 是否包含 infoTitle 或 infoMessage
        if (hasInfo) {
            _bundle = [specifier.target bundle] ?: [NSBundle mainBundle];
            _infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
            _infoButton.translatesAutoresizingMaskIntoConstraints = NO;
            [_infoButton addTarget:self action:@selector(infoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:_infoButton];
            _infoButton.tintColor = [UIColor systemBlueColor];
            [NSLayoutConstraint activateConstraints:@[
                [_infoButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
                [_infoButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-4],
            ]];
        }
    }
    return self;
}

  //Show alert
-(IBAction)infoButtonTapped {
  NSString *title = ([self.specifier propertyForKey:@"infoTitle"]) ?: nil;
  NSString *message = [self.specifier propertyForKey:@"infoMessage"] ?: nil;
  NSString *localizedMessage = [_bundle localizedStringForKey:message value:message table:[self.specifier propertyForKey:@"localizationTable"]];

  UIAlertController *infoAlert = [UIAlertController alertControllerWithTitle:title message:[localizedMessage stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"] preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];

  [infoAlert addAction:cancelAction];

  UIViewController *rootViewController = self._viewControllerForAncestor ?: [UIApplication sharedApplication].keyWindow.rootViewController;
  [rootViewController presentViewController:infoAlert animated:YES completion:nil];
}

/*
  //Tint info button
-(void)tintColorDidChange {
  [super tintColorDidChange];

  _infoButton.tintColor = self.tintColor;
}

-(void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
  [super refreshCellContentsWithSpecifier:specifier];

  if([self respondsToSelector:@selector(tintColor)]) {
    _infoButton.tintColor = self.tintColor;
  }
}
*/
@end

