#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@interface MITLibrariesDate : NSObject <MITMappedObject, NSCoding>

@property (nonatomic, strong) NSString *start;
@property (nonatomic, strong) NSString *end;

@property (nonatomic, readonly) NSDate *startDate;
@property (nonatomic, readonly) NSDate *endDate;

- (NSString *)hoursRangesString;
- (NSString *)dayRangesString;

@end
