#import <Foundation/Foundation.h>
#import "REACHPLAYERPreferences.h"
#import <AudioToolbox/AudioServices.h>

// 定义偏好设置重新加载的通知名称
static NSString *preferencesNotification = @"com.lhh.reachplayerprefs/ReloadPrefs";

// 定义资源包路径，兼容不同系统路径
#define bundlePath @"/var/jb/Library/PreferenceBundles/reachplayerprefs.bundle/"

// 定义偏好设置文件路径，兼容不同系统路径
#define plistPath @"/var/jb/var/mobile/Library/Preferences/com.lhh.reachplayerprefs.plist"

// 全局按钮项和视图控制器声明
UIBarButtonItem *respringButtonItem;   // 重启按钮
UIViewController *popController;       // 弹出控制器

@implementation REACHPLAYERPreferencesListController

// 加载偏好设置项
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

// 设置表格样式为分组样式
- (UITableViewStyle)tableViewStyle {
    return UITableViewStyleInsetGrouped;
}

// 初始化方法
- (instancetype)init {
    self = [super init];
    if (self) {
        // 创建“应用设置”按钮
        UIButton *respringButton = [UIButton buttonWithType:UIButtonTypeCustom];
        respringButton.frame = CGRectMake(0,0,30,30);
        respringButton.layer.cornerRadius = respringButton.frame.size.height / 2;
        respringButton.layer.masksToBounds = YES;
        respringButton.backgroundColor = [UIColor colorWithRed:72/255.0f green:97/255.0f blue:112/255.0f alpha:1.0f];
        [respringButton setImage:[[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@CHECKMARK.png", bundlePath]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [respringButton addTarget:self action:@selector(apply:) forControlEvents:UIControlEventTouchUpInside];
        respringButton.tintColor = [UIColor colorWithRed:121/255.0f green:145/255.0f blue:153/255.0f alpha:1.0f];
        respringButtonItem = [[UIBarButtonItem alloc] initWithCustomView:respringButton];
        

        
        // 将按钮添加到导航栏右侧
        NSArray *rightButtons = @[respringButtonItem];
        self.navigationItem.rightBarButtonItems = rightButtons;
        self.navigationItem.titleView = [UIView new];
        
        // 设置标题标签
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.text = @"";
        self.titleLabel.textColor = [UIColor colorWithRed:121/255.0f green:145/255.0f blue:153/255.0f alpha:1.0f];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.navigationItem.titleView addSubview:self.titleLabel];
        
        // 设置图标视图
        self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        self.iconView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@icon.png", bundlePath]];
        self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
        self.iconView.alpha = 0.0;
        [self.navigationItem.titleView addSubview:self.iconView];
        
        // 设置布局约束
        [NSLayoutConstraint activateConstraints:@[
            [self.titleLabel.topAnchor constraintEqualToAnchor:self.navigationItem.titleView.topAnchor],
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.navigationItem.titleView.leadingAnchor],
            [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.navigationItem.titleView.trailingAnchor],
            [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.navigationItem.titleView.bottomAnchor],
            [self.iconView.topAnchor constraintEqualToAnchor:self.navigationItem.titleView.topAnchor],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.navigationItem.titleView.leadingAnchor],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.navigationItem.titleView.trailingAnchor],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.navigationItem.titleView.bottomAnchor],
        ]];
    }
    return self;
}

// 设置弹出控制器的呈现样式
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

// 视图即将显示时调用
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.tintColor = [UIColor colorWithRed:121/255.0f green:145/255.0f blue:153/255.0f alpha:1.0f];
    [[UIApplication sharedApplication] keyWindow].tintColor = [UIColor colorWithRed:121/255.0f green:145/255.0f blue:153/255.0f alpha:1.0f];
    self.navigationController.navigationController.navigationBar.tintColor = [UIColor colorWithRed:121/255.0f green:145/255.0f blue:153/255.0f alpha:1.0f];
    self.navigationController.navigationController.navigationBar.translucent = YES;
}

// 返回表格单元格
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.tableHeaderView = self.headerView;
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

// 视图加载完成时调用
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.tintColor = [UIColor colorWithRed:121/255.0f green:145/255.0f blue:153/255.0f alpha:1.0f];
    [[UIApplication sharedApplication] keyWindow].tintColor = [UIColor colorWithRed:121/255.0f green:145/255.0f blue:153/255.0f alpha:1.0f];
    self.navigationController.navigationController.navigationBar.tintColor = [UIColor colorWithRed:121/255.0f green:145/255.0f blue:153/255.0f alpha:1.0f];
    self.navigationController.navigationController.navigationBar.translucent = YES;
    
    // 设置头部视图
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,200,200)];
    self.headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,200,200)];
    self.headerImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.headerImageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@banner.png", bundlePath]];
    self.headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerView addSubview:self.headerImageView];
    
    // 设置头部视图的布局约束
    [NSLayoutConstraint activateConstraints:@[
        [self.headerImageView.topAnchor constraintEqualToAnchor:self.headerView.topAnchor],
        [self.headerImageView.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor],
        [self.headerImageView.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor],
        [self.headerImageView.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
    ]];
    
    _table.tableHeaderView = self.headerView;
    
    // 注册通知监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleNoGesture:)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
}

// 滚动视图滚动时调用
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    
    // 根据滚动位置切换标题和图标显示
    if (offsetY > 40) {
        [UIView animateWithDuration:0.2 animations:^{
            self.iconView.alpha = 1.0;
            self.titleLabel.alpha = 0.0;
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.iconView.alpha = 0.0;
            self.titleLabel.alpha = 1.0;
        }];
    }
    
    // 调整头部视图高度
    if (offsetY > 0) offsetY = 0;
    self.headerImageView.frame = CGRectMake(self.headerView.frame.origin.x, self.headerView.frame.origin.y, self.headerView.frame.size.width, 200 - offsetY);
}

// 视图即将消失时调用
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
}

// 读取偏好设置值
-(id)readPreferenceValue: (PSSpecifier *)specifier {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:plistPath]];
    return settings [specifier.properties[@"key"]] ?: specifier.properties[@"default"];
}

// 设置偏好设置值
-(void)setPreferenceValue:(id)value specifier: (PSSpecifier *)specifier {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary: [NSDictionary dictionaryWithContentsOfFile:plistPath]];
    [settings setObject:value forKey:specifier.properties [@"key"]];
    [settings writeToFile:plistPath atomically:YES];
    [super setPreferenceValue:value specifier :specifier];
    
    // 发送通知
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)preferencesNotification, NULL, NULL, TRUE);
}

// 点击“应用设置”按钮时调用
- (void)apply:(UIButton *)sender {
    popController = [[UIViewController alloc] init];
    popController.modalPresentationStyle = UIModalPresentationPopover;
    popController.preferredContentSize = CGSizeMake(200,130);
    
    // 添加提示标签
    UILabel *respringLabel = [[UILabel alloc] init];
    respringLabel.frame = CGRectMake(20, 20, 160, 60);
    respringLabel.numberOfLines = 2;
    respringLabel.textAlignment = NSTextAlignmentCenter;
    respringLabel.adjustsFontSizeToFitWidth = YES;
    respringLabel.font = [UIFont boldSystemFontOfSize:20];
    respringLabel.textColor = [UIColor colorWithRed:121/255.0f green:145/255.0f blue:153/255.0f alpha:1.0f];
    respringLabel.text = @"您确定要执行 注销 操作吗？";
    [popController.view addSubview:respringLabel];
    
    // 添加“是”按钮
    UIButton *yesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [yesButton addTarget:self action:@selector(handleYesGesture) forControlEvents:UIControlEventTouchUpInside];
    [yesButton setTitle:@"是" forState:UIControlStateNormal];
    yesButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [yesButton setTitleColor:[UIColor colorWithRed:121/255.0f green:145/255.0f blue:153/255.0f alpha:1.0f] forState:UIControlStateNormal];
    yesButton.frame = CGRectMake(100, 100, 100, 30);
    [popController.view addSubview:yesButton];
    
    // 添加“否”按钮
    UIButton *noButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [noButton addTarget:self action:@selector(handleNoGesture:) forControlEvents:UIControlEventTouchUpInside];
    [noButton setTitle:@"否" forState:UIControlStateNormal];
    noButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [noButton setTitleColor:[UIColor colorWithRed:121/255.0f green:145/255.0f blue:153/255.0f alpha:1.0f] forState:UIControlStateNormal];
    noButton.frame = CGRectMake(0, 100, 100, 30);
    [popController.view addSubview:noButton];
    
    // 设置弹出控制器样式
    UIPopoverPresentationController *popover = popController.popoverPresentationController;
    popover.delegate = self;
    popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    popover.barButtonItem = respringButtonItem;
    popover.backgroundColor = [UIColor colorWithRed:72/255.0f green:97/255.0f blue:112/255.0f alpha:1.0f];
    
    // 显示弹出控制器
    [self presentViewController:popController animated:YES completion:nil];
    AudioServicesPlaySystemSound(1519); // 播放系统声音
}


// 处理“是”按钮点击事件
- (void)handleYesGesture {
    AudioServicesPlaySystemSound(1519);
    [popController dismissViewControllerAnimated:YES completion:nil];
    
    // 重启SpringBoard
    pid_t pid;
    const char* args[] = {"killall", "SpringBoard", NULL};
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/killall"]) {
        posix_spawn(&pid, "usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
    } else {
        posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
    }
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)preferencesNotification, NULL, NULL, TRUE);
}

// 处理“否”按钮点击事件
- (void)handleNoGesture:(UIButton *)sender {
    [popController dismissViewControllerAnimated:YES completion:nil];
}

- (void)zdyprefs {
    // 👉 你想打开的路径写在这里
    // 获取路径（兼容 Rootless）
    NSString *path = @"/Library/PreferenceBundles/reachplayerprefs.bundle/PresetThemes/";
    #if __has_include(<rootless.h>)
    path = [@"/var/jb" stringByAppendingPathComponent:path]; // Rootless 修正
    #endif

    // 生成 Filza URL
    NSString *encodedPath = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSString *filzaURLString = [NSString stringWithFormat:@"filza://%@", encodedPath];
    NSURL *url = [NSURL URLWithString:filzaURLString];

    // 打开 Filza
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                NSLog(@"Failed to open Filza. URL: %@", filzaURLString);
            }
        }];
    } else {
        NSLog(@"Filza is not installed.");
    }
}

- (void)resetPrefs {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"重置设置"
                         message:@"确定要重置所有设置吗？"
                  preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancel = [UIAlertAction
        actionWithTitle:@"取消"
                  style:UIAlertActionStyleCancel
                handler:nil];

    UIAlertAction *confirm = [UIAlertAction
        actionWithTitle:@"确定"
                  style:UIAlertActionStyleDestructive
                handler:^(UIAlertAction *action) {

                    // 初始化用户默认设置对象
                    NSUserDefaults *prefs = [[NSUserDefaults standardUserDefaults] init];
                    // 移除指定域的所有偏好设置
                    [prefs removePersistentDomainForName:@"com.lhh.reachplayerprefs"];

                    // ✅ 删除实际生效的偏好文件
                    NSFileManager *fm = [NSFileManager defaultManager];
                    if ([fm fileExistsAtPath:plistPath]) {
                        NSError *error = nil;
                        [fm removeItemAtPath:plistPath error:&error];
                    }

                    // ✅ 通知插件重新加载设置
                    CFNotificationCenterPostNotification(
                        CFNotificationCenterGetDarwinNotifyCenter(),
                        (CFStringRef)preferencesNotification,
                        NULL, NULL, TRUE
                    );

                    //[self respringWithAnimation];
                }];

    [alert addAction:cancel];
    [alert addAction:confirm];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)respringWithAnimation {
    // 禁用视图交互，防止在重启动画期间用户进行其他操作
    self.view.userInteractionEnabled = NO;

    // 创建毛玻璃视觉效果视图
    // UIBlurEffectStyleSystemChromeMaterial 是系统提供的材质模糊效果
    UIVisualEffectView *matEffect = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial]];
    matEffect.alpha = 0.0F;  // 初始完全透明
    matEffect.translatesAutoresizingMaskIntoConstraints = NO;  // 使用自动布局
    
    // 获取应用的主窗口根视图控制器的视图
    UIView *view = [UIApplication sharedApplication].keyWindow.rootViewController.view;
    [view addSubview:matEffect];  // 将毛玻璃效果添加到最顶层
    
    // 设置自动布局约束，让毛玻璃效果覆盖整个屏幕
    [NSLayoutConstraint activateConstraints:@[
        [matEffect.widthAnchor constraintEqualToAnchor:view.widthAnchor],      // 宽度等于屏幕宽
        [matEffect.heightAnchor constraintEqualToAnchor:view.heightAnchor],    // 高度等于屏幕高
        [matEffect.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],  // 水平居中
        [matEffect.centerYAnchor constraintEqualToAnchor:view.centerYAnchor]   // 垂直居中
    ]];

    // 执行动画：毛玻璃效果逐渐显现
    [UIView animateWithDuration:1.0f      // 动画时长1秒
        delay:0.0f                        // 无延迟立即开始
        options:UIViewAnimationOptionCurveEaseIn  // 缓入动画曲线（先慢后快）
        animations:^{
            matEffect.alpha = 1.0F;  // 将透明度从0变为1（完全显示）
        }
        completion:^(BOOL finished) {
            // 动画完成后执行重启操作
            
        // 使用posix_spawn重启SpringBoard
        pid_t pid;  // 进程ID
        const char* args[] = {"killall", "SpringBoard", NULL};  // 命令行参数
                    
        // 检查killall命令路径（兼容不同越狱环境）
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/killall"]) {
            posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
            } else {
                posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
            }

            // 方法2：延迟退出设置应用本身
            // 在1秒后退出当前应用，确保重启过程完整
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                exit(0);  // 退出应用，返回状态码0（正常退出）
            });
        }];
}
@end


// 以下是其他偏好设置子控制器的实现，功能与主控制器类似，只是加载的Plist文件不同
@implementation REACHPLAYERACTIVATIONPreferencesListController
// 加载并返回specifiers数组，用于构建设置界面
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"ACTIVATION" target:self];
    }
    return _specifiers;
}
// 设置表格视图的样式
- (UITableViewStyle)tableViewStyle {
    return UITableViewStyleInsetGrouped;
}
// 读取偏好设置值的方法
-(id)readPreferenceValue: (PSSpecifier *)specifier {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:plistPath]];
    return settings [specifier.properties[@"key"]] ?: specifier.properties[@"default"];
}
// 设置偏好设置值的方法
-(void)setPreferenceValue:(id)value specifier: (PSSpecifier *)specifier {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary: [NSDictionary dictionaryWithContentsOfFile: plistPath]];
    [settings setObject:value forKey:specifier.properties [@"key"]];
    [settings writeToFile:plistPath atomically:YES];
    [super setPreferenceValue:value specifier :specifier];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)preferencesNotification, NULL, NULL, TRUE);
}
@end
// 背景设置控制器的实现
@implementation REACHPLAYERLAYOUTPreferencesListController
// 加载并返回specifiers数组，用于构建设置界面
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"LAYOUT" target:self];
    }
    return _specifiers;
}
// 设置表格视图的样式
- (UITableViewStyle)tableViewStyle {
    return UITableViewStyleInsetGrouped;// 返回UITableViewStyleInsetGrouped样式，这是iOS 13+引入的圆角分组样式
}
// 读取偏好设置值的方法
-(id)readPreferenceValue: (PSSpecifier *)specifier {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:plistPath]];
    return settings [specifier.properties[@"key"]] ?: specifier.properties[@"default"];
}
// 设置偏好设置值的方法
-(void)setPreferenceValue:(id)value specifier: (PSSpecifier *)specifier {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary: [NSDictionary dictionaryWithContentsOfFile: plistPath]];
    [settings setObject:value forKey:specifier.properties [@"key"]];
    [settings writeToFile:plistPath atomically:YES];
    [super setPreferenceValue:value specifier :specifier];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)preferencesNotification, NULL, NULL, TRUE);
}
@end
// 背景设置控制器的实现
@implementation REACHPLAYERBACKGROUNDPreferencesListController
// 加载并返回specifiers数组，用于构建设置界面
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"BACKGROUND" target:self];
    }
    return _specifiers;
}
// 设置表格视图的样式
- (UITableViewStyle)tableViewStyle {
    return UITableViewStyleInsetGrouped;
}
// 读取偏好设置值的方法
-(id)readPreferenceValue: (PSSpecifier *)specifier {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:plistPath]];
    return settings [specifier.properties[@"key"]] ?: specifier.properties[@"default"];
}
// 设置偏好设置值的方法
-(void)setPreferenceValue:(id)value specifier: (PSSpecifier *)specifier {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary: [NSDictionary dictionaryWithContentsOfFile: plistPath]];
    [settings setObject:value forKey:specifier.properties [@"key"]];
    [settings writeToFile:plistPath atomically:YES];
    [super setPreferenceValue:value specifier :specifier];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)preferencesNotification, NULL, NULL, TRUE);
}
@end
