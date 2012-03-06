#import <Foundation/Foundation.h>

@interface TouchstoneResponse : NSObject
@property (nonatomic, retain) NSError *error;

@property (nonatomic, readonly, retain) NSURL *touchstoneURL;
@property (nonatomic, retain) NSString *userFieldName;
@property (nonatomic, retain) NSString *passwordFieldName;

@property (nonatomic, readonly) BOOL isSAMLAssertion;
@property (nonatomic, readonly, retain) NSDictionary *touchstoneParameters;

- (id)initWithRequest:(NSURLRequest*)request data:(NSData*)data;
@end
