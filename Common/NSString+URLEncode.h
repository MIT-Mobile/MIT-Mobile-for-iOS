#import <Foundation/Foundation.h>


@interface NSString (MITURLEncoding)
- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding useFormURLEncoded:(BOOL)formUrlEncoded;
- (NSString*)urlDecodeUsingEncoding:(NSStringEncoding)encoding;
@end
