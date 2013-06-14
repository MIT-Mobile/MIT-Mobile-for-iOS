#import <Foundation/Foundation.h>

@interface DiningData : NSObject

+ (DiningData *)sharedData;
- (void)reload;

@property (nonatomic, strong, readonly) NSString *announcementsHTML;
@property (nonatomic, strong, readonly) NSArray *links;

@end
