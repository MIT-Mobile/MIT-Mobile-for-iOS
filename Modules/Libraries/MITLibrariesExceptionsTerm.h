#import <Foundation/Foundation.h>
#import "MITMappedObject.h"
#import "MITLibrariesTermProtocol.h"

@class MITLibrariesDate;

@interface MITLibrariesExceptionsTerm : NSObject <MITMappedObject, MITLibrariesTermProtocol, NSCoding>

@property (nonatomic, strong) MITLibrariesDate *dates;
@property (nonatomic, strong) MITLibrariesDate *hours;
@property (nonatomic, strong) NSString *reason;

- (BOOL)isOpenOnDate:(NSDate *)date;
- (BOOL)isOpenOnDayOfDate:(NSDate *)date;

@end
