#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@interface MITLibrariesAskUsModel : NSObject <MITMappedObject>

@property (nonatomic, strong) NSArray *topics;
@property (nonatomic, strong) NSArray *consultationLists;

@end
