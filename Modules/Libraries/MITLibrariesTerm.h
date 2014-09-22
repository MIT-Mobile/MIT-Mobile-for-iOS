#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@interface MITLibrariesTerm : NSObject <MITMappedObject>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *dates;

@end
