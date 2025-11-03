#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <spawn.h>
#import "LHHRootListController.h"

// UIPopoverPresentationController的私有类别，用于自定义弹出窗口样式
@interface UIPopoverPresentationController (Private)
// 私有属性：设置弹出窗口的背景样式（Apple未公开的API）
@property (assign,setter=_setPopoverBackgroundStyle:,nonatomic) long long _popoverBackgroundStyle;
// 私有属性：禁用背景模糊效果
@property (assign,setter=_setBackgroundBlurDisabled:,nonatomic) BOOL _backgroundBlurDisabled;
@end



// 主设置列表控制器
@interface REACHPLAYERPreferencesListController : LHHRootListController<UIPopoverPresentationControllerDelegate> {
    UITableView * _table;  // 表格视图
}

// 各种UI组件和属性
@property (nonatomic, retain) UIBarButtonItem *killButton;       // 杀死进程的按钮
@property (nonatomic, retain) UIView *headerView;                // 头部视图
@property (nonatomic, retain) UIImageView *headerImageView;      // 头部图片视图
@property (nonatomic, retain) UILabel *titleLabel;               // 标题标签
@property (nonatomic, retain) UIImageView *iconView;             // 图标视图

// 自定义方法
- (void)apply:(UIButton *)sender;            // 应用设置

- (void)handleYesGesture;                    // 处理"是"手势
- (void)handleNoGesture:(UIButton *)sender;  // 处理"否"手势
@end

@interface REACHPLAYERACTIVATIONPreferencesListController : LHHRootListController
@end

@interface REACHPLAYERLAYOUTPreferencesListController : LHHRootListController
@end

@interface REACHPLAYERBACKGROUNDPreferencesListController : LHHRootListController
@end
