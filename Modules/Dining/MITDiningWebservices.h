#import <Foundation/Foundation.h>
#import "MITDiningDining.h"

typedef void(^MITDiningCompletionBlock)(MITDiningDining *dining, NSError *error);

@interface MITDiningWebservices : NSObject

+ (void)getDiningWithCompletion:(MITDiningCompletionBlock)completion;

@end
