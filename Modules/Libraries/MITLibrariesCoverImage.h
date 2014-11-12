#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@interface MITLibrariesCoverImage : NSObject <MITMappedObject>

@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;
@property (nonatomic, strong) NSString *url;

@end
