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
- (BOOL)containsSubstring:(NSString*)string options:(NSStringCompareOptions)mask;

@end

@interface NSString (MITAdditions_URLEncoding)
- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding useFormURLEncoded:(BOOL)formUrlEncoded;
- (NSString*)urlDecodeUsingEncoding:(NSStringEncoding)encoding;
@end

@interface NSString (MITAdditions_HTMLEntity)
- (NSString *)stringByDecodingXMLEntities;
@end


@interface UIDevice (MITAdditions)
- (NSString*)sysInfoByName:(NSString*)typeSpecifier;
- (NSString*)cpuType;
@end