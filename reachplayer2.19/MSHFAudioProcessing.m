#import "public/MSHFAudioProcessing.h"

@interface MSHFAudioProcessing () {
    // A计权
    float *aWeights;
    
    // 锯齿消除
    float *smoothedBuffer;
    int smoothWindowSize;
    
    // 闪动优化
    float *previousSpectrum;
    float smoothFactor;
    
    // 频带划分
    int frequencyBands;
    float startFrequency;
    float endFrequency;
    float *bandAmplitudes;
    NSArray<NSValue *> *bands; // 存储频带范围的NSValue数组
}
@end

@implementation MSHFAudioProcessing

- (id)initWithBufferSize:(int)bufferSize {
    self = [super init];
    
    numberOfFrames = bufferSize;
    numberOfFramesOver2 = numberOfFrames / 2;
    fftNormFactor = -1.0 / 256.0;
    
    // FFT缓冲区
    outReal = (float *)malloc(sizeof(float) * numberOfFramesOver2);
    outImaginary = (float *)malloc(sizeof(float) * numberOfFramesOver2);
    out = (float *)malloc(sizeof(float) * numberOfFramesOver2);
    output.realp = outReal;
    output.imagp = outImaginary;
    
    // 汉宁窗
    window = (float *)malloc(sizeof(float) * numberOfFrames);
    vDSP_hann_window(window, numberOfFrames, vDSP_HANN_NORM);
    
    // FFT初始化
    bufferLog2 = round(log2(numberOfFrames));
    fftSetup = vDSP_create_fftsetup(bufferLog2, kFFTRadix2);
    
    // A计权初始化
    aWeights = [self createAWeightingCurve];
    
    // 锯齿消除初始化
    smoothWindowSize = 7;
    smoothedBuffer = (float *)malloc(sizeof(float) * numberOfFramesOver2);
    
    // 闪动优化初始化
    previousSpectrum = (float *)malloc(sizeof(float) * numberOfFramesOver2);
    memset(previousSpectrum, 0, sizeof(float) * numberOfFramesOver2);
    smoothFactor = 0.5;
    
    // 频带划分初始化（默认80个频带，100Hz-18kHz）
    frequencyBands = 64;
    startFrequency = 150;
    endFrequency = 1500;
    bandAmplitudes = (float *)malloc(sizeof(float) * frequencyBands);
    [self setupFrequencyBands];
    
    return self;
}

- (void)dealloc {
    free(outReal);
    free(outImaginary);
    free(out);
    free(window);
    free(aWeights);
    free(smoothedBuffer);
    free(previousSpectrum);
    free(bandAmplitudes);
    vDSP_destroy_fftsetup(fftSetup);
}

#pragma mark - 频带划分
- (void)setupFrequencyBands {
    NSMutableArray *tempBands = [NSMutableArray array];
    
    // 计算对数增长的频带
    float n = log2f(endFrequency / startFrequency) / frequencyBands;
    float lower = startFrequency;
    
    for (int i = 0; i < frequencyBands; i++) {
        float upper = (i == frequencyBands - 1) ? endFrequency : lower * powf(2, n);
        float bandRange[2] = {lower, upper};
        [tempBands addObject:[NSValue valueWithBytes:&bandRange objCType:@encode(float[2])]];
        lower = upper;
    }
    
    bands = [tempBands copy];
}

- (float)findMaxAmplitudeInBand:(float)lower upper:(float)upper amplitudes:(float *)amplitudes bandWidth:(float)bandWidth {
    int startIndex = (int)round(lower / bandWidth);
    int endIndex = MIN((int)round(upper / bandWidth), numberOfFramesOver2 - 1);
    
    float maxVal = 0;
    vDSP_maxv(amplitudes + startIndex, 1, &maxVal, endIndex - startIndex + 1);
    return maxVal;
}


#pragma mark - A计权
- (float *)createAWeightingCurve {
    float *weights = (float *)malloc(sizeof(float) * numberOfFramesOver2);
    float sampleRate = 44100.0;
    
    for (int i = 0; i < numberOfFramesOver2; i++) {
        float f = i * (sampleRate / numberOfFrames);
        weights[i] = [self aWeightingForFrequency:f];
    }
    
    return weights;
}

- (float)aWeightingForFrequency:(float)f {
    float fSquared = f * f;
    float c1 = powf(12194.217, 2.0);
    float c2 = powf(20.598997, 2.0);
    float c3 = powf(107.65265, 2.0);
    float c4 = powf(737.86223, 2.0);
    
    float numerator = c1 * fSquared * fSquared;
    float denominator = (fSquared + c2) * sqrtf((fSquared + c3) * (fSquared + c4)) * (fSquared + c1);
    
    return 1.2589 * numerator / denominator;
}

#pragma mark - 锯齿消除
- (void)smoothSpectrum:(float *)data length:(int)length {
    if (smoothWindowSize < 3) return;
    
    int halfWindow = smoothWindowSize / 2;
    float weights[] = {1, 2, 3, 5, 3, 2, 1};
    float weightSum = 17.0;
    
    for (int i = halfWindow; i < length - halfWindow; i++) {
        float sum = 0;
        for (int j = 0; j < smoothWindowSize; j++) {
            sum += data[i - halfWindow + j] * weights[j];
        }
        smoothedBuffer[i] = sum / weightSum;
    }
    
    memcpy(data + halfWindow, smoothedBuffer + halfWindow,
           sizeof(float) * (length - 2 * halfWindow));
}

#pragma mark - 闪动优化
- (void)applyFrameSmoothing:(float *)currentSpectrum length:(int)length {
    float oneMinusFactor = 1.0 - smoothFactor;
    vDSP_vsmsma(currentSpectrum, 1,
               &oneMinusFactor,
               previousSpectrum, 1,
               &smoothFactor,
               currentSpectrum, 1,
               length);
    
    memcpy(previousSpectrum, currentSpectrum, sizeof(float) * length);
}

#pragma mark - 主处理流程
- (void)process:(float *)data withLength:(int)length {
    if (!self.delegate) return;
    
    if (self.fft && length == numberOfFrames) {
        // 1. 加窗 -> FFT -> 取模
        vDSP_vmul(data, 1, window, 1, data, 1, numberOfFrames);
        vDSP_ctoz((COMPLEX *)data, 2, &output, 1, numberOfFramesOver2);
        vDSP_fft_zrip(fftSetup, &output, 1, bufferLog2, FFT_FORWARD);
        vDSP_zvabs(&output, 1, out, 1, numberOfFramesOver2);
        vDSP_vsmul(out, 1, &fftNormFactor, out, 1, numberOfFramesOver2);
        
        // 2. A计权
        vDSP_vmul(out, 1, aWeights, 1, out, 1, numberOfFramesOver2);
        
        // 3. 频带划分
        float sampleRate = 44100.0;
        float bandWidth = sampleRate / numberOfFrames;
        for (int i = 0; i < frequencyBands; i++) {
            float range[2];
            [bands[i] getValue:range];
            bandAmplitudes[i] = [self findMaxAmplitudeInBand:range[0]
                                                       upper:range[1]
                                                 amplitudes:out
                                                  bandWidth:bandWidth];
        }
        
        // 4. 锯齿消除（在频带上处理）
        //[self smoothSpectrum:bandAmplitudes length:frequencyBands];
        
        // 5. 闪动优化（在频带上处理）
        //[self applyFrameSmoothing:bandAmplitudes length:frequencyBands];
        
        // 6. 输出处理后的频带数据
        [self.delegate setSampleData:bandAmplitudes length:frequencyBands];
    } else {
        [self.delegate setSampleData:data length:length];
    }
}

@end
