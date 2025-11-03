#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Hex)

/// 从十六进制字符串创建颜色（支持格式：#RGB、#RGBA、#RRGGBB、#RRGGBBAA）
/// @param hexString 十六进制字符串（例如 @"#FF0000" 或 @"#FF000080"）
/// @return 无效格式时返回 nil
+ (nullable UIColor *)colorWithHexString:(NSString *)hexString;

/// 从十六进制整数值创建颜色（不透明，格式：0xRRGGBB）
/// @param hex 十六进制值（例如 0xFF0000）
+ (nonnull UIColor *)colorWithHex:(UInt32)hex;

/// 从十六进制整数值创建颜色（带透明度）
/// @param hex 十六进制值（格式：0xRRGGBB）
/// @param alpha 透明度（0.0 ~ 1.0）
+ (nonnull UIColor *)colorWithHex:(UInt32)hex alpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
/*
 // 不透明红色
 UIColor *red = [UIColor colorWithHexString:@"#FF0000"];

 // 半透明红色（alpha = 0.5）
 UIColor *semiTransparentRed = [UIColor colorWithHexString:@"#FF000080"];

 // 缩写格式：半透明蓝色（alpha ≈ 0.53）
 UIColor *semiTransparentBlue = [UIColor colorWithHexString:@"#00F8"];
 */
