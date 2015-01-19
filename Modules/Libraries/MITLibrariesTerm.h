#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@class MITLibrariesDate;

@interface MITLibrariesTerm : NSObject <MITMappedObject, NSCoding>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) MITLibrariesDate *dates;

@property (nonatomic, strong) NSArray *regularTerm;
@property (nonatomic, strong) NSArray *closingsTerm;
@property (nonatomic, strong) NSArray *exceptionsTerm;

- (NSString *)termDescription;
- (NSString *)termHoursDescription;
- (BOOL)dateFallsInTerm:(NSDate *)date;
- (NSString *)hoursStringForDate:(NSDate *)date;
- (BOOL)isOpenAtDate:(NSDate *)date;
- (BOOL)isOpenOnDayOfDate:(NSDate *)date;

@end
