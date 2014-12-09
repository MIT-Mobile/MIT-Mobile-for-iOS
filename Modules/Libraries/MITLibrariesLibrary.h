#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

extern NSString *const kMITLibraryClosedMessageString;

@interface MITLibrariesLibrary : NSObject <MITMappedObject>

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSArray *terms;

- (NSString *)hoursStringForDate:(NSDate *)date;
- (BOOL)isOpenAtDate:(NSDate *)date;

@end
