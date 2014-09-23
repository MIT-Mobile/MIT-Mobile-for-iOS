#import <Foundation/Foundation.h>

@interface MITLibrariesCitation : NSObject

- (instancetype)initWithName:(NSString *)name citation:(NSString *)citation;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *citation;

@end
