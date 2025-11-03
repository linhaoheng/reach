#import <UIKit/UIKit.h>
#import "LHHNowPlayingProgressKnobView.h"

@interface LHHNowPlayingProgressView : UIView

@property (nonatomic, assign, readonly) BOOL isTracking;
@property (nonatomic, assign) BOOL highlighted;
@property (nonatomic, assign) double elapsedTime;
@property (nonatomic, assign) double duration;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UIView *elapsedTrack;
@property (nonatomic, strong) UIView *remainingTrack;

@property (nonatomic, strong) LHHNowPlayingProgressKnobView *knobView;

@property (nonatomic, strong) UILabel *elapsedLabel;
@property (nonatomic, strong) UILabel *remainingLabel;

@property (nonatomic, strong) NSLayoutConstraint *elapsedTrackWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *knobViewCenterXConstraint;
@property (nonatomic, assign) CGFloat trackWidth; // 当前 layout 后的实际宽度

- (void)startTimer;
- (void)stopTimer;
- (void)updateNowPlayingImmediately;
@end
