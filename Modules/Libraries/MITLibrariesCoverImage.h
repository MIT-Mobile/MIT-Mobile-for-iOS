#import <Foundation/Foundation.h>
#import "MITInitializableWithDictionaryProtocol.h"
#import "MITMappedObject.h"

@interface MITLibrariesCoverImage : NSObject <MITInitializableWithDictionaryProtocol, MITMappedObject>

@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;
@property (nonatomic, strong) NSString *url;

@end
