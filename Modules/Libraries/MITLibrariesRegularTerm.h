#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@class MITLibrariesDate;

@interface MITLibrariesRegularTerm : NSObject <MITMappedObject>

@property (nonatomic, strong) NSString *days;
@property (nonatomic, strong) MITLibrariesDate *hours;

@end
