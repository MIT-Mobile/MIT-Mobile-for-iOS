#import <Foundation/Foundation.h>

@interface DiningData : NSObject

+ (DiningData *)sharedData;
- (void)reloadAndCompleteWithBlock:(void (^)())completionBlock;

@property (nonatomic, strong, readonly) NSString *announcementsHTML;
@property (nonatomic, strong, readonly) NSArray *links;
@property (nonatomic, strong, readonly) NSDate *lastUpdated;
@property (nonatomic, strong) NSArray *allFlags;

@end
