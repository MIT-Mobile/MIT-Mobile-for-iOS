#import <Foundation/Foundation.h>
#import "MITToursStop.h"

@interface MITToursStopCellModel : NSObject

@property (nonatomic, strong) MITToursStop *stop;

@property (nonatomic) NSInteger stopIndex;

@property (nonatomic, readonly) NSString *titleText;
@property (nonatomic, readonly) NSString *distanceText;

- (instancetype)initWithStop:(MITToursStop *)stop
                   stopIndex:(NSInteger)stopIndex;

@end
