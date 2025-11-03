#import "MSHFView.h"
#import "MSHFJelloLayer.h"

@interface MSHFJelloView : MSHFView
@property(nonatomic, assign) NSInteger padCount;
@property(nonatomic, strong) MSHFJelloLayer *waveLayer;
@property(nonatomic, strong) MSHFJelloLayer *subwaveLayer;
- (instancetype)initWithFrame:(CGRect)frame;

@end

