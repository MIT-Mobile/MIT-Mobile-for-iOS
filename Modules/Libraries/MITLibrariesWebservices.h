#import <Foundation/Foundation.h>

@interface MITLibrariesWebservices : NSObject

+ (void)getLinksWithCompletion:(void (^)(NSArray *links, NSError *error))completion;
+ (void)getLibrariesWithCompletion:(void (^)(NSArray *libraries, NSError *error))completion;

@end
