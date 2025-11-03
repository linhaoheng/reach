#import "UIColor+Hex.h"

@implementation UIColor (Hex)

+ (UIColor *)colorWithHexString:(NSString *)hexString {
    if (!hexString || hexString.length == 0) {
        return [UIColor whiteColor]; // 无效输入返回白色
    }
    
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // RGB
            alpha = 1.0f;
            red   = [self _colorComponentFrom:colorString start:0 length:1];
            green = [self _colorComponentFrom:colorString start:1 length:1];
            blue  = [self _colorComponentFrom:colorString start:2 length:1];
            break;
        case 4: // RGBA
            red   = [self _colorComponentFrom:colorString start:0 length:1];
            green = [self _colorComponentFrom:colorString start:1 length:1];
            blue  = [self _colorComponentFrom:colorString start:2 length:1];
            alpha = [self _colorComponentFrom:colorString start:3 length:1];
            break;
        case 6: // RRGGBB
            alpha = 1.0f;
            red   = [self _colorComponentFrom:colorString start:0 length:2];
            green = [self _colorComponentFrom:colorString start:2 length:2];
            blue  = [self _colorComponentFrom:colorString start:4 length:2];
            break;
        case 8: // RRGGBBAA
            red   = [self _colorComponentFrom:colorString start:0 length:2];
            green = [self _colorComponentFrom:colorString start:2 length:2];
            blue  = [self _colorComponentFrom:colorString start:4 length:2];
            alpha = [self _colorComponentFrom:colorString start:6 length:2];
            break;
        default:
            return [UIColor whiteColor]; // 无效格式返回白色
    }
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *)colorWithHex:(UInt32)hex {
    return [self colorWithHex:hex alpha:1.0f];
}

+ (UIColor *)colorWithHex:(UInt32)hex alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0f
                           green:((hex >> 8) & 0xFF) / 255.0f
                            blue:(hex & 0xFF) / 255.0f
                           alpha:alpha];
}

#pragma mark - Private

+ (CGFloat)_colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length {
    NSString *substring = [string substringWithRange:NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat:@"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString:fullHex] scanHexInt:&hexComponent];
    return hexComponent / 255.0f;
}

@end
