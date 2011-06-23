#import <Foundation/Foundation.h>


@interface NSString (URLEncoding)
- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
- (NSString*)urlDecodeUsingEncoding:(NSStringEncoding)encoding;
@end
