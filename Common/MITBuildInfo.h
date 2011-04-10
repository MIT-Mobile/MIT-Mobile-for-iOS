#import <Foundation/Foundation.h>


@interface MITBuildInfo : NSObject

+ (NSString *)revision;
+ (NSString *)description;
+ (CGImageRef)newHashImage;

@end