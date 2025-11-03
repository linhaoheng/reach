#import "LHHRootListController.h"

@implementation LHHRootListController

/**
 * 加载specifier的方法
 * 如果specifier尚未加载，则从plist文件加载
 */
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

/**
 * 视图加载完成时调用
 * 初始化动态specifier的嵌套关系
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNestedSpecifiers:self.specifiers]; // ✅ 初始化动态控制关系
}

/**
 * 设置嵌套specifier的方法
 * 将包含nestedEntryCount属性的specifier与其子specifier关联起来
 * @param specifiers 原始specifier数组
 */
- (void)setupNestedSpecifiers:(NSArray *)specifiers {
    self.dynamicSpecifiers = [NSMutableDictionary dictionary]; // 初始化动态specifier字典
    
    for (NSUInteger i = 0; i < specifiers.count; i++) {
        PSSpecifier *spec = specifiers[i];
        NSNumber *countNum = [spec propertyForKey:@"nestedEntryCount"]; // 获取nestedEntryCount属性
        if (countNum) {
            NSInteger count = countNum.integerValue; // 获取子specifier数量
            NSMutableArray *controlled = [NSMutableArray array]; // 存储子specifier的数组
            for (NSInteger j = 1; j <= count && (i + j) < specifiers.count; j++) {
                [controlled addObject:specifiers[i + j]]; // 将子specifier添加到数组
            }
            self.dynamicSpecifiers[@(i)] = controlled; // 将父specifier与子specifier关联
        }
    }
    
    self.hasDynamicSpecifiers = (self.dynamicSpecifiers.count > 0); // 标记是否有动态specifier
}

/**
 * 设置specifier值的方法
 * 当specifier值改变时调用
 * @param value 新的值
 * @param specifier 被修改的specifier
 */
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier]; // 调用父类方法
    
    // 如果有动态specifier，刷新表格高度
    if (self.hasDynamicSpecifiers) {
        [self reloadSpecifiers]; // 如果有动态specifier，重新加载
    }
}
- (void)reloadSpecifiers {
    [self.table endEditing:YES]; // 结束表格编辑
    [self.table beginUpdates];   // 开始刷新（带动画）
    [self.table endUpdates];     // 结束刷新

}
/**
 * 计算表格行高的方法
 * 如果specifier被禁用，则返回高度为0（隐藏该行）
 * @param tableView 表格视图
 * @param indexPath 行索引路径
 * @return 行高
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.hasDynamicSpecifiers) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }

    PSSpecifier *current = [self specifierAtIndexPath:indexPath];
    for (NSNumber *index in self.dynamicSpecifiers) {
        NSArray *controlled = self.dynamicSpecifiers[index];
        if ([controlled containsObject:current]) {
            PSSpecifier *controller = self.specifiers[index.integerValue];
            
            id value = [self readPreferenceValue:controller];
            NSString *stringValue = [value isKindOfClass:[NSNumber class]] ? [value stringValue] : value;
            
            if ([stringValue isEqualToString:@"0"]) {
                UITableViewCell *cell = [current propertyForKey:PSTableCellKey];
                cell.clipsToBounds = YES;
                return 0;
            }
        }
    }

    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

@end
