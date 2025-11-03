#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface LHHRootListController : PSListController
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSArray *> *dynamicSpecifiers;
@property (nonatomic, assign) BOOL hasDynamicSpecifiers;
@end
