#import <Foundation/Foundation.h>

@interface MITShuttleRoutesDataSource : NSObject <NSCopying>
@property(nonatomic,copy,readonly) NSArray *routes;
@property(nonatomic) NSTimeInterval expiryInterval;

- (void)routes:(void(^)(MITShuttleRoutesDataSource *dataSource, NSError *error))completion;
@end