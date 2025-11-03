// MSHFJelloLayer.m
#import "public/MSHFJelloLayer.h"

@implementation MSHFJelloLayer

- (id<CAAction>)actionForKey:(NSString *)event {
    if ([event isEqualToString:@"path"]) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:event];
        animation.duration = 0.15;
        return animation;
    }
    return [super actionForKey:event];
}

@end
