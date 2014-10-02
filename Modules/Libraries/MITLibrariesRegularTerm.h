#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@class MITLibrariesDate;

@interface MITLibrariesRegularTerm : NSObject <MITMappedObject>

@property (nonatomic, strong) NSString *days;
@property (nonatomic, strong) MITLibrariesDate *hours;

- (BOOL)isOpenOnDate:(NSDate *)date;
- (BOOL)isOpenOnDayOfDate:(NSDate *)date;
- (NSString *)termHoursDescription;

@end
