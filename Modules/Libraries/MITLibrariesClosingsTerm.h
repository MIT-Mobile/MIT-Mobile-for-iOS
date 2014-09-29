#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@class MITLibrariesDate;

@interface MITLibrariesClosingsTerm : NSObject <MITMappedObject>

@property (nonatomic, strong) MITLibrariesDate *dates;
@property (nonatomic, strong) NSString *reason;

@end
