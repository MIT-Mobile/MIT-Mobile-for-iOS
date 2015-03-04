#import "MITBuildInfo.h"

@implementation MITBuildInfo

// e.g. 7411fb9d43ee94febaeb4e5b97f4408f4c22ca64
+ (NSString *)revision {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:MITBuildRevisionKey];
}

// e.g. 3.0.1-34-g7411fb9
+ (NSString *)description {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:MITBuildDescriptionKey];
}


+ (CGImageRef)newHashImage {
    NSUInteger width = 4; // 4px x 4px, 32-bit RGBA
    NSUInteger height = 4;
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerLine = width * bytesPerPixel;
    void *bitmapData = calloc(height, bytesPerLine);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef offscreen = CGBitmapContextCreate(bitmapData, width, height, 8, bytesPerLine, colorspace, kCGImageAlphaNoneSkipLast);
    
    NSString *hash = [MITBuildInfo revision];
    
    NSInteger i = 0;
    NSInteger c = 0;
    NSInteger length = [hash length];
    NSInteger limit = width * height * bytesPerPixel;
    char *p = NULL;
    for (i = 0; i < length; i++) {
        if (c <= limit) {
            p = bitmapData + c;
            *p = ([hash characterAtIndex:i] % 39 - 9) * 16;
        }
        c++;
        // skip alpha
        if (c % bytesPerPixel == bytesPerPixel - 1) {
            c++;
        }
    }
    // keep repeating the pattern until we run out of pixels
    while (c < limit) {
        c += bytesPerPixel - (c % bytesPerPixel);
        long remainder = limit - c;
        memcpy(bitmapData + c, bitmapData, (remainder <= c) ? remainder : c);
        c += limit - c;
    }
    
    CGImageRef image = CGBitmapContextCreateImage(offscreen);
    CGContextRelease(offscreen);
    CGColorSpaceRelease(colorspace);
    free(bitmapData);
    return image; // +1 retain count
}

@end
