#import <Foundation/Foundation.h>

@interface MITToursWebservices : NSObject

+ (void)getToursWithCompletion:(void (^)(NSArray *tours, NSError *error))completion;

@end
