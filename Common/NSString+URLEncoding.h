#import <Foundation/Foundation.h>


@interface NSString (URLEncoding)
- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding useFormURLEncoded:(BOOL)formUrlEncoded;
- (NSString*)urlDecodeUsingEncoding:(NSStringEncoding)encoding;
@end
