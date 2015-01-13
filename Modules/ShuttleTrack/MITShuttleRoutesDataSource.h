#import <Foundation/Foundation.h>
#import "MITShuttleDataSource.h"

@interface MITShuttleRoutesDataSource : MITShuttleDataSource

@property(nonatomic,copy,readonly) NSArray *routes;

- (void)updateRoutes:(void(^)(MITShuttleRoutesDataSource *dataSource, NSError *error))completion;

@end
