#import <Foundation/Foundation.h>
#import "MITMappedObject.h"
#import "MITLibrariesTermProtocol.h"

@class MITLibrariesDate;

@interface MITLibrariesClosingsTerm : NSObject <MITMappedObject, MITLibrariesTermProtocol>

@property (nonatomic, strong) MITLibrariesDate *dates;
@property (nonatomic, strong) NSString *reason;

- (BOOL)isClosedOnDate:(NSDate *)date;

@end
