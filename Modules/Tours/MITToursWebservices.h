#import <Foundation/Foundation.h>

@class MITToursTour;

@interface MITToursWebservices : NSObject

+ (void)getToursWithCompletion:(void (^)(id object, NSError *error))completion;
+ (void)getTourDetailForTour:(MITToursTour *)tour completion:(void (^)(id object, NSError *error))completion;

@end
