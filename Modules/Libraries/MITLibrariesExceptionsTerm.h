#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@class MITLibrariesDate;

@interface MITLibrariesExceptionsTerm : NSObject <MITMappedObject>

@property (nonatomic, strong) MITLibrariesDate *dates;
@property (nonatomic, strong) MITLibrariesDate *hours;
@property (nonatomic, strong) NSString *reason;

- (BOOL)isOpenOnDate:(NSDate *)date;
- (BOOL)isOpenOnDayOfDate:(NSDate *)date;
- (NSString *)hoursString;

@end
