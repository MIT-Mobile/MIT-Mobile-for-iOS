#import <Foundation/Foundation.h>
#import "MITInitializableWithDictionaryProtocol.h"

@interface MITLibrariesCoverImage : NSObject <MITInitializableWithDictionaryProtocol>

@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;
@property (nonatomic, strong) NSString *url;

@end
