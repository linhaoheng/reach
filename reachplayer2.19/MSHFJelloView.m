#import "public/MSHFJelloView.h"

@implementation MSHFJelloView {
    // 缓存计算结果（与尺寸相关的固定值）
    CGFloat _totalBarUnit;
    NSInteger _windowSize;
    float *_weights; // 缓存平滑权重的C数组
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _padCount = 0;
        _windowSize = 10; // 平滑窗口大小（原逻辑固定为10）
        [self initializeWaveLayers];
        self.points = (CGPoint *)malloc(sizeof(CGPoint) * self.numberOfPoints);
        [self precomputeWeights]; // 预计算平滑权重（仅初始化一次）
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 缓存与尺寸相关的固定值（总单位宽度）
    CGFloat barWidth = 2.0;
    CGFloat spacing = 0.5;
    _totalBarUnit = barWidth + spacing;
}

// 预计算平滑权重（替代原每次调用smoothHeights时的重复计算）
- (void)precomputeWeights {
    if (_weights) free(_weights);
    
    NSInteger weightCount = 2 * _windowSize + 1;
    _weights = (float *)malloc(sizeof(float) * weightCount);
    
    CGFloat sigma = _windowSize / 2.0;
    CGFloat twoSigmaSq = 2 * sigma * sigma;
    
    for (NSInteger i = -_windowSize; i <= _windowSize; i++) {
        NSInteger index = i + _windowSize;
        _weights[index] = exp(-(i * i) / twoSigmaSq);
    }
}

- (void)initializeWaveLayers {
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    self.subwaveLayer = [MSHFJelloLayer layer];
    self.waveLayer = [MSHFJelloLayer layer];
    
    self.subwaveLayer.frame = self.bounds;
    self.waveLayer.frame = self.bounds;
    
    self.waveLayer.zPosition = 0;
    self.subwaveLayer.zPosition = -1;
    
    [self.layer addSublayer:self.waveLayer];
    [self.layer addSublayer:self.subwaveLayer];
    
    [self configureDisplayLink];
    [self resetWaveLayers];
}

- (void)resetWaveLayers {
    if (!self.points) return;
    
    CGPathRef path = [self createPath];
    self.waveLayer.path = path;
    self.subwaveLayer.path = path;
    CGPathRelease(path);
}

- (void)updateWaveColor:(CGColorRef)waveColor subwaveColor:(CGColorRef)subwaveColor {
    self.waveColor = waveColor;
    self.subwaveColor = subwaveColor;
    self.waveLayer.fillColor = waveColor;
    self.subwaveLayer.fillColor = subwaveColor;
}

- (void)redraw {
    [super redraw];
    
    CGPathRef path = [self createPath];
    self.waveLayer.path = path;
    
    // 异步给 subwave 加延迟效果（保留原逻辑）
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.subwaveLayer.path = path;
        }
        CGPathRelease(path); // 修复原逻辑可能的内存泄漏
    });
}

#pragma mark - 柱状图路径生成（核心优化：改用C数组，保留原逻辑）
- (CGPathRef)createPath {
    CGMutablePathRef path = CGPathCreateMutable();
    if (!self.points || self.numberOfPoints < 1) return path;
    
    // ===== 1. 配置参数 =====
    CGFloat width = self.bounds.size.width;
    CGFloat barWidth = 2.0;
    CGFloat spacing = 0.5;
    CGFloat totalBarUnit = barWidth + spacing;
    NSInteger barCount = (NSInteger)(width / totalBarUnit);
    
    // ===== 2. 动态固定点定义 =====
    CGPoint virtualStartPoint = CGPointMake(0, self.waveOffset);
    CGPoint virtualEndPoint = CGPointMake(width, self.waveOffset);
    NSInteger totalVirtualPoints = self.numberOfPoints + 2; // 动态点 + 首尾固定点
    
    // ===== 3. 插值计算柱高 =====
    float *barHeights = (float *)malloc(sizeof(float) * barCount);
    for (NSInteger i = 0; i < barCount; i++) {
        CGFloat progress = (CGFloat)i / (CGFloat)(barCount - 1);
        CGFloat virtualIndex = progress * (totalVirtualPoints - 1);
        
        // 动态映射到实际点
        float y;
        if (virtualIndex <= 0) {
            y = virtualStartPoint.y; // 固定起点
        } else if (virtualIndex >= totalVirtualPoints - 1) {
            y = virtualEndPoint.y; // 固定终点
        } else {
            // 动态点插值（索引偏移 -1）
            CGFloat dataPos = virtualIndex - 1;
            NSInteger lowerIdx = (NSInteger)floor(dataPos);
            NSInteger upperIdx = MIN(lowerIdx + 1, self.numberOfPoints - 1);
            CGFloat t = dataPos - lowerIdx;
            
            y = self.points[lowerIdx].y + (self.points[upperIdx].y - self.points[lowerIdx].y) * t;
        }
        barHeights[i] = MAX(1.0, self.waveOffset - y);
    }
    
    // ===== 4. 过渡点处理 =====
    NSInteger extendedCount = barCount + self.padCount * 2;
    float *extendedHeights = (float *)malloc(sizeof(float) * extendedCount);
    
    // 前过渡
    for (NSInteger i = self.padCount; i > 0; i--) {
        CGFloat t = (CGFloat)i / (CGFloat)(self.padCount + 1);
        extendedHeights[self.padCount - i] = [self exponentialInterpolateFrom:barHeights[1]
                                                                         to:barHeights[0]
                                                                         t:t
                                                                  exponent:3.0];
    }
    
    // 原始数据
    memcpy(extendedHeights + self.padCount, barHeights, sizeof(float) * barCount);
    
    // 后过渡
    for (NSInteger i = 1; i <= self.padCount; i++) {
        CGFloat t = (CGFloat)i / (CGFloat)(self.padCount + 1);
        extendedHeights[self.padCount + barCount + i - 1] =
            [self exponentialInterpolateFrom:barHeights[barCount - 2]
                                         to:barHeights[barCount - 1]
                                         t:t
                                  exponent:3.0];
    }
    
    // ===== 5. 平滑处理 =====
    float *smoothedHeights = (float *)malloc(sizeof(float) * extendedCount);
    for (NSInteger i = 0; i < extendedCount; i++) {
        CGFloat weightedSum = 0;
        CGFloat weightTotal = 0;
        
        for (NSInteger j = -_windowSize; j <= _windowSize; j++) {
            NSInteger idx = i + j;
            idx = MAX(0, MIN(idx, extendedCount - 1));
            CGFloat w = _weights[j + _windowSize];
            weightedSum += extendedHeights[idx] * w;
            weightTotal += w;
        }
        smoothedHeights[i] = weightedSum / weightTotal;
    }
    
    // ===== 6. 生成路径 =====
    CGFloat totalWidth = extendedCount * totalBarUnit;
    CGFloat xOffset = (width - totalWidth) / 2.0;
    for (NSInteger i = 0; i < extendedCount; i++) {
        CGFloat x = xOffset + i * totalBarUnit;
        CGRect rect = CGRectMake(x, self.waveOffset - smoothedHeights[i], barWidth, smoothedHeights[i]);
        CGPathAddRect(path, NULL, rect);
    }
    
    // ===== 7. 释放内存 =====
    free(barHeights);
    free(extendedHeights);
    free(smoothedHeights);
    
    return path;
}

// 指数插值函数（完全保留原逻辑）
- (CGFloat)exponentialInterpolateFrom:(CGFloat)y1 to:(CGFloat)y2 t:(CGFloat)t exponent:(CGFloat)exponent {
    CGFloat factor = 1.0 - pow(1.0 - t, exponent);
    return y1 + (y2 - y1) * factor;
}

#pragma mark - 内存管理
- (void)dealloc {
    if (_weights) {
        free(_weights);
        _weights = NULL;
    }
    if (self.points) {
        free(self.points);
        self.points = NULL;
    }
}

@end
