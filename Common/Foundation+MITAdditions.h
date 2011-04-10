#import <Foundation/Foundation.h>

@interface NSURL (MITAdditions)

+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path;
+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path query:(NSString *)query;

@end

@interface NSMutableString (MITAdditions)

- (void)replaceOccurrencesOfStrings:(NSArray *)targets withStrings:(NSArray *)replacements options:(NSStringCompareOptions)options;

@end

@interface NSString (MITAdditions)

- (NSString *)substringToMaxIndex:(NSUInteger)to;

@end