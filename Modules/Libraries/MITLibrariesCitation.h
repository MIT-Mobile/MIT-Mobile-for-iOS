#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@interface MITLibrariesCitation : NSObject <MITMappedObject>

- (instancetype)initWithName:(NSString *)name citation:(NSString *)citation;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *citation;

@end
